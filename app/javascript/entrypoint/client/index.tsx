import { createRoot } from "react-dom/client";
import { loadRoutes } from "@/src/utils/loadPaths";
import { createBrowserRouter, RouterProvider } from "react-router";

import "flowbite";

const rootElement = document.getElementById("react-app");
const router = createBrowserRouter(loadRoutes());

console.log("🚀 Loaded routes:", loadRoutes());

if (rootElement) {
	const root = createRoot(rootElement);

	root.render(<RouterProvider router={router} />);

	// Development logging
	if (import.meta.env.DEV) {
		console.log("🚀 React app mounted successfully!");
	}
} else {
	console.error('Could not find root element with id "react-app"');
}
