import type { RouteObject } from "react-router";

export function loadRoutes(): RouteObject[] {
	// For now, let's just return a simple route structure
	// You can expand this as needed
	const modules = import.meta.glob("../pages/**/*.tsx", { eager: true });

	const routes: RouteObject[] = [];

	Object.values(modules).forEach((mod: any) => {
		if (mod.routePath && !mod.routePath.skip) {
			routes.push(mod.routePath);
		}
	});

	// If no routes found, return an empty array for now
	return routes;
}
