import { createRoot } from "react-dom/client";
import { loadRoutes } from "@/src/utils/loadPaths";
import { createBrowserRouter, RouterProvider } from "react-router";

import "flowbite";
import { ThemeProvider, createTheme } from "flowbite-react";

const rootElement = document.getElementById("react-app");
const router = createBrowserRouter(loadRoutes());

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
			<RouterProvider router={router} />
		</ThemeProvider>
	);

	// Development logging
	if (import.meta.env.DEV) {
		console.log("🚀 React app mounted successfully!");
	}
} else {
	console.error('Could not find root element with id "react-app"');
}
