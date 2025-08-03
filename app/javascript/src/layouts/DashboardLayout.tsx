import React from "react";

// Root layout
const DashboardLayout = ({ children }: React.PropsWithChildren) => {
	return <div className="block md:grid md:grid-cols-[250px_1fr] w-full h-screen">{children}</div>;
};

// Sidebar component
DashboardLayout.Sidebar = function Sidebar({ children }: React.PropsWithChildren) {
	return <aside className="h-full overflow-y-auto hidden md:block">{children}</aside>;
};

// Content component
DashboardLayout.Content = function Content({ children }: React.PropsWithChildren) {
	return (
		<main className="flex-1 p-6 md:m-2.5 md:ml-0 md:mb-0 overflow-y-auto bg-white rounded-tr-xl rounded-tl-xl border border-gray-200">
			{children}
		</main>
	);
};

export default DashboardLayout;
