import { Sidebar, SidebarItem, SidebarItemGroup, SidebarItems } from "flowbite-react";
import { LayoutDashboard, Gauge, ClipboardMinus, LogOut } from "lucide-react";

const SidebarComponent = () => {
	return (
		<Sidebar
			className="h-screen hidden md:block bg-transparent"
			color="transparent"
			aria-label="Default sidebar example"
		>
			<SidebarItems className="my-2 flex-col flex h-[calc(100vh-3rem)]">
				<a href="#" className="flex items-center">
					<img src="/undp.svg" alt="UNDP Logo" className="h-12 w-auto" />
					<p className="pl-2 text-lg font-semibold">UNDP Business</p>
				</a>
				<SidebarItemGroup>
					<SidebarItem href="#" icon={LayoutDashboard}>
						Dashboard
					</SidebarItem>
					<SidebarItem icon={Gauge} href="#" label="Pro" labelColor="dark">
						Analytics
					</SidebarItem>
					<SidebarItem href="#" label="5" labelColor="purple" active icon={ClipboardMinus}>
						Assessments
					</SidebarItem>
				</SidebarItemGroup>

				<div className="mt-auto">
					<SidebarItemGroup className="mt-auto">
						<SidebarItem href="/logout" icon={LogOut}>
							Sign Out
						</SidebarItem>
					</SidebarItemGroup>
				</div>
			</SidebarItems>
		</Sidebar>
	);
};

export default SidebarComponent;
