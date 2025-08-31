import { User } from '../contexts/AuthContext';

// Get the appropriate home route based on user role
export const getHomeRoute = (user: { user: User } | null): string => {
	if (!user) {
		return '/app/login';
	}
	
	return user.user?.admin ? '/app' : '/app/dashboard';
};

// Get display name for the home route
export const getHomeRouteName = (user: { user: User } | null): string => {
	if (!user) {
		return 'Login';
	}
	
	return user.user?.admin ? 'Admin Dashboard' : 'Dashboard';
};