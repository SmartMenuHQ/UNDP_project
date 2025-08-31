import React from "react";
import { Navigate, useLocation } from "react-router";
import { useAuth } from "../contexts/AuthContext";
import { getHomeRoute } from "../utils/navigation";

interface RouteGuardProps {
	children: React.ReactNode;
	requireAdmin?: boolean;
	fallbackPath?: string;
}

const RouteGuard: React.FC<RouteGuardProps> = ({
	children,
	requireAdmin = false,
	fallbackPath,
}) => {
	const { user, isLoading } = useAuth();
	const location = useLocation();

	// Show loading while authentication is being determined
	if (isLoading) {
		return (
			<div className="flex items-center justify-center h-screen">
				<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
			</div>
		);
	}

	// If not authenticated, redirect to login
	if (!user) {
		return <Navigate to="/app/login" replace />;
	}

	// If admin access required but user is not admin, redirect to their appropriate home
	if (requireAdmin && !user.user?.admin) {
		const redirectPath = fallbackPath || getHomeRoute(user);
		return <Navigate to={redirectPath} replace />;
	}

	// If user is admin but accessing non-admin dashboard, redirect to admin dashboard
	console.log(location.pathname);
	if (!requireAdmin && user.user?.admin && location.pathname === "/app/dashboard") {
		return <Navigate to="/app" replace />;
	}

	// Only render children if all checks pass
	return <>{children}</>;
};

export default RouteGuard;
