import { RouteObject, Navigate } from "react-router";

function Home() {
	return <Navigate to="/simple-demo" replace />;
}

export const routePath = {
	path: "/",
	Component: Home,
} as RouteObject;
