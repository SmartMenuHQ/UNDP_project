import { createRoot } from "react-dom/client";
import { loadRoutes } from "@/src/utils/loadPaths";
import { createBrowserRouter, RouteObject, RouterProvider } from "react-router";

import "flowbite";
import { ThemeProvider, createTheme } from "flowbite-react";
import { routePath as notFoundRoute } from "@/src/pages/404";
import ErrorBoundary from "@/src/components/ErrorBoundary";
import { AuthProvider } from "@/src/contexts/AuthContext";
import ProtectedRoute from "@/src/components/ProtectedRoute";

const rootElement = document.getElementById("react-app");

// Wrap protected routes with ProtectedRoute component
const routes = loadRoutes().map(route => {
  // Login page should not be protected
  if (route.path === "/app/login") {
    return route;
  }
  
  // All other /app/* routes should be protected
  if (route.path?.startsWith("/app")) {
    return {
      ...route,
      Component: route.Component ? () => (
        <ProtectedRoute>
          <route.Component />
        </ProtectedRoute>
      ) : undefined
    };
  }
  
  return route;
});

const router = createBrowserRouter([...routes, notFoundRoute]);

console.log("🚀 Loaded routes:", loadRoutes());

const theme = createTheme({
	sidebar: {
		root: {
			inner: "bg-transparent",
			collapsed: {
				off: "w-full",
			},
			item: {
				active: "bg-gray-100 dark:bg-gray-700",
				icon: {
					base: "h-[20px] w-[20px]",
				},
			},
		},
	},
	button: {
		base: "cursor-pointer",
	},
});

if (rootElement) {
	const root = createRoot(rootElement);

	root.render(
		<ThemeProvider theme={theme}>
			<ErrorBoundary>
				<AuthProvider>
					<RouterProvider router={router} />
				</AuthProvider>
			</ErrorBoundary>
		</ThemeProvider>
	);

	// Development logging
	if (import.meta.env.DEV) {
		console.log("🚀 React app mounted successfully!");
	}
} else {
	console.error('Could not find root element with id "react-app"');
}
