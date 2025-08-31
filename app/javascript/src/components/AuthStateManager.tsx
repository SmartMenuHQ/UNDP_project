import { useEffect, useRef } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface AuthStateManagerProps {
	children: React.ReactNode;
}

interface UserSession {
	id: number | null;
	admin: boolean;
}

// Component to manage auth state transitions and prevent cross-user data leaking
const AuthStateManager: React.FC<AuthStateManagerProps> = ({ children }) => {
	const { user, isAuthenticated } = useAuth();
	const previousSessionRef = useRef<UserSession | null>(null);

	useEffect(() => {
		const currentSession: UserSession = {
			id: user?.user?.id || null,
			admin: user?.user?.admin || false
		};
		
		const previousSession = previousSessionRef.current;

		// If we have a different user session than before (user or role switched)
		if (previousSession !== null && (
			currentSession.id !== previousSession.id ||
			currentSession.admin !== previousSession.admin
		)) {
			console.log('User session changed, forcing page reload:', {
				previous: previousSession,
				current: currentSession
			});
			
			// Force a full page reload to clear all component state
			// This ensures no data from the previous user/role persists
			window.location.reload();
			return;
		}

		// Update the ref for next comparison
		previousSessionRef.current = currentSession;
	}, [user?.user?.id, user?.user?.admin]);

	// Clear the session ref when user logs out
	useEffect(() => {
		if (!isAuthenticated) {
			previousSessionRef.current = null;
		}
	}, [isAuthenticated]);

	return <>{children}</>;
};

export default AuthStateManager;