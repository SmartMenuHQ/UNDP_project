import { useEffect, useRef } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface AuthStateManagerProps {
	children: React.ReactNode;
}

// Component to manage auth state transitions and prevent cross-user data leaking
const AuthStateManager: React.FC<AuthStateManagerProps> = ({ children }) => {
	const { user, isAuthenticated } = useAuth();
	const previousUserIdRef = useRef<number | null>(null);

	useEffect(() => {
		const currentUserId = user?.user?.id || null;
		const previousUserId = previousUserIdRef.current;

		// If we have a different user than before (user switched)
		if (previousUserId !== null && currentUserId !== previousUserId) {
			// Force a full page reload to clear all component state
			// This ensures no data from the previous user persists
			window.location.reload();
			return;
		}

		// Update the ref for next comparison
		previousUserIdRef.current = currentUserId;
	}, [user?.user?.id]);

	// Clear the user ID ref when user logs out
	useEffect(() => {
		if (!isAuthenticated) {
			previousUserIdRef.current = null;
		}
	}, [isAuthenticated]);

	return <>{children}</>;
};

export default AuthStateManager;