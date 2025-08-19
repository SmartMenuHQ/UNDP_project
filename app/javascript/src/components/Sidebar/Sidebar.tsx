"use client";

import { Sidebar, SidebarItem, SidebarItemGroup, SidebarItems } from "flowbite-react";
import { 
	Home, 
	LayoutTemplate, 
	FolderOpen, 
	Folder, 
	ChevronDown, 
	ChevronRight, 
	Users, 
	Plus,
	Zap
} from "lucide-react";
import Listbox from "../Listbox/Listbox";
import { useState } from "react";

const SidebarComponent = () => {
	const [isMyAssessmentsOpen, setIsMyAssessmentsOpen] = useState(true);
	const [isSharedOpen, setIsSharedOpen] = useState(false);
	
	const workspaces = [
		{ value: "ws1", label: "Workspace name" },
		{ value: "ws2", label: "Another workspace" },
	];

	return (
		<Sidebar
			className="h-screen hidden md:block bg-transparent"
			color="transparent"
			aria-label="Assessment sidebar"
		>
			<div className="my-2 flex-col flex h-[calc(100vh-3rem)] px-3">
				{/* Workspace Selector */}
				<div className="mb-6">
					<Listbox
						options={workspaces}
						defaultValue={{ value: "ws1", label: "Workspace name" }}
						onChange={(value) => console.log("Selected:", value)}
					/>
				</div>

				{/* Main Navigation */}
				<SidebarItems>
					<SidebarItemGroup>
						<SidebarItem href="#" icon={Home} active>
							Home
						</SidebarItem>
						<SidebarItem href="#" icon={LayoutTemplate}>
							Templates
						</SidebarItem>
					</SidebarItemGroup>
				</SidebarItems>

				{/* My Assessments Section */}
				<div className="mb-4">
					<button
						onClick={() => setIsMyAssessmentsOpen(!isMyAssessmentsOpen)}
						className="flex items-center w-full text-left px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg"
					>
						<FolderOpen className="w-5 h-5 mr-2 text-gray-500" />
						<span className="flex-1">My Assessments</span>
						{isMyAssessmentsOpen ? (
							<ChevronDown className="w-4 h-4 text-gray-400" />
						) : (
							<ChevronRight className="w-4 h-4 text-gray-400" />
						)}
					</button>
					
					{isMyAssessmentsOpen && (
						<div className="ml-7 mt-1 space-y-0.5">
							<a href="#" className="flex items-center px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg">
								<Folder className="w-4 h-4 mr-2 text-gray-500" />
								Research
							</a>
							<a href="#" className="flex items-center px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg">
								<Folder className="w-4 h-4 mr-2 text-gray-500" />
								Development
							</a>
							<a href="#" className="flex items-center px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg">
								<Folder className="w-4 h-4 mr-2 text-gray-500" />
								Policy
							</a>
							<a href="#" className="flex items-center px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg">
								<Folder className="w-4 h-4 mr-2 text-gray-500" />
								Governance
							</a>
							<button className="flex items-center w-full text-left px-3 py-1.5 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg">
								See all
							</button>
						</div>
					)}
				</div>

				{/* Shared with Me Section */}
				<div className="mb-4">
					<button
						onClick={() => setIsSharedOpen(!isSharedOpen)}
						className="flex items-center w-full text-left px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg"
					>
						<Users className="w-5 h-5 mr-2 text-gray-500" />
						<span className="flex-1">Shared with Me</span>
						{isSharedOpen ? (
							<ChevronDown className="w-4 h-4 text-gray-400" />
						) : (
							<ChevronRight className="w-4 h-4 text-gray-400" />
						)}
					</button>
				</div>

				{/* Add Folder */}
				<button className="flex items-center w-full text-left px-3 py-2 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg mb-6">
					<Plus className="w-5 h-5 mr-2" />
					Add Folder
				</button>

				{/* Automations Section */}
				<div className="border-t border-gray-200 pt-4">
					<p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
						Automations
					</p>
					<SidebarItems>
						<SidebarItemGroup>
							<SidebarItem href="#" icon={Zap}>
								Manage Triggers
							</SidebarItem>
						</SidebarItemGroup>
					</SidebarItems>
				</div>

				{/* Footer */}
				<div className="mt-auto pt-4 border-t border-gray-200">
					<p className="text-[11px] text-gray-400 text-center">&copy; Powered by UNDP</p>
				</div>
			</div>
		</Sidebar>
	);
};

export default SidebarComponent;
