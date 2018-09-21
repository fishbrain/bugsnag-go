package sessions

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	//contextSessionKey is a unique key for accessing and setting Bugsnag
	//session data on a context.Context object
	contextSessionKey ctxKey = 1
)

// ctxKey is a type alias that ensures uniqueness as a context.Context key
type ctxKey int

// SessionTracker exposes a method for starting sessions that are used for
// gauging your application's health
type SessionTracker interface {
	StartSession(context.Context) context.Context
	GetSession(context.Context) *Session
	FlushSessions()
}

type sessionTracker struct {
	sessionChannel chan *Session
	sessions       []*Session
	config         *SessionTrackingConfiguration
	publisher      sessionPublisher
}

// NewSessionTracker creates a new SessionTracker based on the provided config,
func NewSessionTracker(config *SessionTrackingConfiguration) SessionTracker {
	publisher := publisher{
		config: config,
		client: &http.Client{Transport: config.Transport},
	}
	st := sessionTracker{
		sessionChannel: make(chan *Session, 1),
		sessions:       []*Session{},
		config:         config,
		publisher:      &publisher,
	}
	go st.processSessions()
	return &st
}

func (s *sessionTracker) GetSession(ctx context.Context) *Session {
	if s := ctx.Value(contextSessionKey); s != nil {
		if session, ok := s.(*Session); ok && !session.StartedAt.IsZero() {
			//It is not just getting back a default value
			return session
		}
	}
	return nil
}

func (s *sessionTracker) StartSession(ctx context.Context) context.Context {
	session := newSession()
	s.sessionChannel <- session
	return context.WithValue(ctx, contextSessionKey, session)
}

func (s *sessionTracker) interval() time.Duration {
	s.config.mutex.Lock()
	defer s.config.mutex.Unlock()
	return s.config.PublishInterval
}

func (s *sessionTracker) processSessions() {
	tic := time.Tick(s.interval())
	shutdown := shutdownSignals()
	for {
		select {
		case session := <-s.sessionChannel:
			s.sessions = append(s.sessions, session)
		case <-tic:
			oldSessions := s.sessions
			s.sessions = nil
			if len(oldSessions) > 0 {
				go func(s *sessionTracker) {
					err := s.publisher.publish(oldSessions)
					if err != nil {
						s.config.logf("%v", err)
					}
				}(s)
			}
		case <-shutdown:
			if len(s.sessions) > 0 {
				err := s.publisher.publish(s.sessions)
				if err != nil {
					s.config.logf("%v", err)
				}
			}
			return
		}
	}
}

func (s *sessionTracker) FlushSessions() {
	sessions := s.sessions
	s.sessions = nil
	if len(sessions) != 0 {
		if err := s.publisher.publish(sessions); err != nil {
			s.config.logf("%v", err)
		}
	}
}

func shutdownSignals() <-chan os.Signal {
	c := make(chan os.Signal)
	signal.Notify(c, syscall.SIGTERM, syscall.SIGINT)
	return c
}
