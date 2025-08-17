import {
	Dropdown,
	DropdownDivider,
	DropdownHeader,
	DropdownItem,
	Navbar,
	NavbarBrand,
	NavbarCollapse,
	NavbarLink,
	NavbarToggle,
	Avatar,
	HR,
	Card,
	Button,
	ButtonGroup,
	Tooltip,
} from "flowbite-react";

import { Trash, Pencil, Eye, Ungroup, LayoutTemplate, FileQuestionMark, Timer } from "lucide-react";

import { RouteObject } from "react-router";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import AssessmentCard, { AssessmentStatus } from "../components/Cards/AssessmentCard";

export default function Homepage() {
	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				<Navbar fluid className="p-0 sm:p-0">
					<NavbarBrand>
						<span className="self-center whitespace-nowrap text-2xl font-bold font-display dark:text-white">
							Assessments
						</span>
					</NavbarBrand>
					<div className="flex md:order-2">
						<Dropdown
							arrowIcon={false}
							inline
							label={
								<Avatar
									alt="User settings"
									rounded
									placeholderInitials="ED"
									className="cursor-pointer hidden md:block"
								/>
							}
						>
							<DropdownHeader>
								<span className="block text-sm">Daniel Eze</span>
								<span className="block truncate text-sm font-medium">daniel@undp.com</span>
							</DropdownHeader>
							<DropdownItem>Dashboard</DropdownItem>
							<DropdownItem>Settings</DropdownItem>
							<DropdownDivider />
							<DropdownItem>Sign out</DropdownItem>
						</Dropdown>
						<NavbarToggle />
					</div>
					<NavbarCollapse className="md:hidden">
						<NavbarLink href="#" active>
							Home
						</NavbarLink>
						<NavbarLink href="#">About</NavbarLink>
						<NavbarLink href="#">Services</NavbarLink>
						<NavbarLink href="#">Pricing</NavbarLink>
						<NavbarLink href="#">Contact</NavbarLink>
					</NavbarCollapse>
				</Navbar>
				<hr className="my-4 h-px border-0 bg-gray-200 dark:bg-gray-700" />

				<section className="flex flex-wrap gap-8 items-center">
					<AssessmentCard
						title="Digital Transformation Readiness"
						description="Assessment to determine organizational readiness for digital transformation initiatives."
						status={AssessmentStatus.ACTIVE}
						date="July 21, 2023"
					/>

					<AssessmentCard
						title="Business Impact Assessment"
						description="Comprehensive assessment to evaluate the impact of business operations on local communities and environment."
						status={AssessmentStatus.DRAFT}
						date="July 20, 2023"
					/>

					<AssessmentCard
						title="Digital Transformation Readiness"
						description="Assessment to determine organizational readiness for digital transformation initiatives."
						status={AssessmentStatus.ACTIVE}
						date="July 21, 2023"
					/>

					<AssessmentCard
						title="Business Impact Assessment"
						description="Comprehensive assessment to evaluate the impact of business operations on local communities and environment."
						status={AssessmentStatus.DRAFT}
						date="July 20, 2023"
					/>

					<AssessmentCard
						title="Business Impact Assessment"
						description="Comprehensive assessment to evaluate the impact of business operations on local communities and environment."
						status={AssessmentStatus.ACTIVE}
						date="July 20, 2023"
					/>
				</section>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app",
	Component: Homepage,
} as RouteObject;
