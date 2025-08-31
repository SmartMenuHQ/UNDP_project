"use client";

import { Sidebar, SidebarItem, SidebarItemGroup, SidebarItems } from "flowbite-react";
import {
	Home,
	FileText,
	UserPlus,
	BarChart3,
	Globe,
	LogOut,
	UserCheck,
	Building2,
} from "lucide-react";
import { useNavigate } from "react-router";
import { useAuth } from "../../contexts/AuthContext";

const SidebarComponent = () => {
	const navigate = useNavigate();
	const { logout, user: userData } = useAuth();
	const user = userData?.user;

	// Generate user initials from email or name
	const getUserInitials = () => {
		if (user?.first_name && user?.last_name) {
			return `${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase();
		} else if (user?.display_name) {
			const names = user.display_name.split(' ');
			if (names.length >= 2) {
				return `${names[0].charAt(0)}${names[names.length - 1].charAt(0)}`.toUpperCase();
			}
			return names[0].charAt(0).toUpperCase();
		} else if (user?.email_address) {
			return user.email_address.charAt(0).toUpperCase();
		}
		return 'U';
	};

	const handleLogout = async () => {
		try {
			await logout();
			// Navigation is handled by the logout function itself
		} catch (error) {
			console.error("Logout error:", error);
			// Force navigation even if logout fails
			window.location.href = '/app/login';
		}
	};

	return (
		<Sidebar
			className="h-screen hidden md:block bg-transparent"
			color="transparent"
			aria-label="Assessment sidebar"
		>
			<div className="my-2 flex-col flex h-[calc(100vh-3rem)] px-3">
				{/* User Profile Section */}
				<div className="mb-6 flex items-center space-x-3 p-3 bg-gray-50 rounded-lg border border-gray-200">
					{/* User Avatar with Initials */}
					<div className="w-10 h-10 bg-purple-600 text-white rounded-full flex items-center justify-center font-medium text-sm">
						{getUserInitials()}
					</div>
					
					{/* User Info */}
					<div className="flex-1 min-w-0">
						<p className="text-sm font-medium text-gray-900 truncate">
							{user?.display_name || user?.full_name || 'User'}
						</p>
						<p className="text-xs text-gray-500 truncate">
							{user?.email_address || 'user@example.com'}
						</p>
					</div>
					
					{/* Admin Badge */}
					{user?.admin && (
						<div className="flex-shrink-0">
							<span className="bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-medium">
								Admin
							</span>
						</div>
					)}
				</div>

				{/* Main Navigation */}
				<SidebarItems>
					<SidebarItemGroup>
						{user?.admin ? (
							// Admin Navigation
							<>
								<SidebarItem href="/app" icon={Home}>
									Dashboard
								</SidebarItem>
								<SidebarItem href="/app/admin/assessments" icon={FileText}>
									Assessments
								</SidebarItem>
								<SidebarItem href="/app/users/invite" icon={UserPlus}>
									Invite User
								</SidebarItem>
								<SidebarItem href="/app/users" icon={UserCheck}>
									Manage Users
								</SidebarItem>
								<SidebarItem href="/app/businesses" icon={Building2}>
									Businesses
								</SidebarItem>
								<SidebarItem href="/app/countries" icon={Globe}>
									Countries
								</SidebarItem>
								<SidebarItem href="/app/response-sessions" icon={BarChart3}>
									Response Sessions
								</SidebarItem>
							</>
						) : (
							// Regular User Navigation
							<>
								<SidebarItem href="/app/dashboard" icon={Home}>
									My Dashboard
								</SidebarItem>
								<SidebarItem href="/app/my-assessments" icon={FileText}>
									My Assessments
								</SidebarItem>
							</>
						)}
					</SidebarItemGroup>
				</SidebarItems>

				{/* Logout Section */}
				<div className="mt-auto pt-4 border-t border-gray-200 space-y-2">
					{/* Sign Out Button */}
					<button
						onClick={handleLogout}
						className="flex items-center justify-center w-full py-2 text-sm text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-red-600 hover:border-red-300 transition-all duration-200"
					>
						<LogOut className="w-4 h-4 mr-2" />
						Sign Out
					</button>

					<p className="text-[11px] text-gray-400 text-center px-3 pb-2">
						&copy; Powered by UNDP
					</p>
				</div>
			</div>
		</Sidebar>
	);
};

export default SidebarComponent;
