"use client";

import { useState, useEffect } from "react";
import {
	Dropdown,
	DropdownDivider,
	DropdownHeader,
	DropdownItem,
	Avatar,
	Card,
	Button,
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeadCell,
	TableRow,
} from "flowbite-react";

import { Plus, Download, Filter, ArrowUpDown, FileText, Calendar, Eye, Edit, Trash2 } from "lucide-react";

import { RouteObject, useNavigate } from "react-router";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { useAuth } from "../contexts/AuthContext";
import { fetchAssessments } from "../api/assessments";

interface Assessment {
	id: number;
	title: string;
	description: string;
	active: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
	sections_count: number;
	questions_count: number;
	created_at: string;
	updated_at: string;
}

export default function Homepage() {
	const navigate = useNavigate();
	const { logout, user } = useAuth();
	const [assessments, setAssessments] = useState<Assessment[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		const loadAssessments = async () => {
			try {
				const data = await fetchAssessments();
				setAssessments(data);
			} catch (err) {
				console.error('Failed to fetch assessments:', err);
				setError(err instanceof Error ? err.message : 'Failed to load assessments');
			} finally {
				setLoading(false);
			}
		};

		loadAssessments();
	}, []);

	const handleNewAssessment = () => {
		navigate('/app/assessments/new');
	};

	const handleSignOut = () => {
		logout();
		navigate('/app/login');
	};

	const handleEditAssessment = (assessmentId: number) => {
		navigate(`/app/assessments/${assessmentId}/sections`);
	};

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				{/* Header */}
				<div className="flex items-center justify-between mb-8">
					<div className="flex items-center space-x-4">
						<h1 className="text-2xl font-bold text-gray-900">Assessments</h1>
					</div>
					<div className="flex items-center space-x-3 relative">
						<div className="relative">
							<Dropdown
								arrowIcon={false}
								inline
								placement="bottom-end"
								label={
									<Avatar
										alt="User settings"
										rounded
										placeholderInitials="DM"
										className="cursor-pointer"
									/>
								}
							>
								<DropdownHeader>
									<span className="block text-sm">{user?.display_name || user?.full_name || 'User'}</span>
									<span className="block truncate text-sm font-medium">{user?.email_address || 'user@undp.com'}</span>
								</DropdownHeader>
								<DropdownItem>Dashboard</DropdownItem>
								<DropdownItem>Settings</DropdownItem>
								<DropdownDivider />
								<DropdownItem onClick={handleSignOut}>Sign out</DropdownItem>
							</Dropdown>
						</div>
					</div>
				</div>

				{/* Main Content */}
				<div className="space-y-6">
					{/* Action Cards Section */}
					<div className="flex gap-6">
						{/* New Assessment Card */}
						<Card className="w-72 border-2 border-dashed border-purple-300 hover:border-purple-400 transition-colors cursor-pointer shadow-none" onClick={handleNewAssessment}>
							<div className="flex flex-col items-center justify-center py-6 text-center">
								<div className="w-12 h-12 bg-purple-200 rounded-lg flex items-center justify-center mb-3">
									<Plus className="w-6 h-6 text-purple-700" />
								</div>
								<h3 className="text-lg font-semibold text-purple-700 mb-1">New assessment</h3>
								<p className="text-sm text-gray-500">Start with a blank assessment</p>
							</div>
						</Card>

						{/* Import Assessment Card */}
						<Card className="w-72 border-2 border-dashed border-orange-300 hover:border-orange-400 transition-colors cursor-pointer shadow-none">
							<div className="flex flex-col items-center justify-center py-6 text-center">
								<div className="w-12 h-12 bg-orange-200 rounded-lg flex items-center justify-center mb-3">
									<Download className="w-6 h-6 text-orange-700" />
								</div>
								<h3 className="text-lg font-semibold text-orange-700 mb-1">Import assessment</h3>
								<p className="text-sm text-gray-500">csv, xls, pdf & more</p>
							</div>
						</Card>
					</div>

					{/* Filter and Sort Controls */}
					<div className="flex items-center justify-between">
						<div className="flex items-center space-x-4">
							<button className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
								<Filter className="w-4 h-4 mr-2" />
								Filter
							</button>
							<button className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
								<ArrowUpDown className="w-4 h-4 mr-2" />
								Sort by
							</button>
						</div>
					</div>

					{/* Assessments Table */}
					<div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
						<Table>
							<TableHead>
								<TableRow className="bg-gray-50 border-b border-gray-200">
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										<div className="flex items-center space-x-3">
											<input type="checkbox" className="rounded border-gray-300" />
											<span>Assessment name</span>
										</div>
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Owner
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Status
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Created
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Responses
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										<span className="sr-only">Actions</span>
									</TableHeadCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{loading ? (
									<TableRow>
										<TableCell colSpan={6} className="px-6 py-8 text-center">
											<div className="flex items-center justify-center">
												<div className="animate-spin rounded-full h-6 w-6 border-b-2 border-purple-600 mr-3"></div>
												Loading assessments...
											</div>
										</TableCell>
									</TableRow>
								) : error ? (
									<TableRow>
										<TableCell colSpan={6} className="px-6 py-8 text-center text-red-600">
											{error}
										</TableCell>
									</TableRow>
								) : assessments.length === 0 ? (
									<TableRow>
										<TableCell colSpan={6} className="px-6 py-8 text-center text-gray-500">
											No assessments found. Create your first assessment to get started.
										</TableCell>
									</TableRow>
								) : (
									assessments.map((assessment, index) => (
										<TableRow key={assessment.id} className={`${index !== assessments.length - 1 ? 'border-b border-gray-200' : ''} hover:bg-gray-50 transition-colors duration-150`}>
											<TableCell className="px-6 py-4">
												<div className="flex items-center space-x-3">
													<input type="checkbox" className="rounded border-gray-300" />
													<div className="flex items-center space-x-3">
														<div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
															<FileText className="w-4 h-4 text-gray-600" />
														</div>
														<span className="font-medium text-gray-900">{assessment.title}</span>
													</div>
												</div>
											</TableCell>
											<TableCell className="px-6 py-4">
												<div className="flex items-center space-x-2">
													<div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
														{user?.first_name?.charAt(0) || 'U'}
													</div>
													<span className="text-gray-900">{user?.display_name || user?.full_name || 'Unknown User'}</span>
												</div>
											</TableCell>
											<TableCell className="px-6 py-4">
												<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
													assessment.active 
														? 'bg-green-100 text-green-800' 
														: 'bg-yellow-100 text-yellow-800'
												}`}>
													{assessment.active ? 'Active' : 'Draft'}
												</span>
											</TableCell>
											<TableCell className="px-6 py-4 text-gray-500">
												<div className="flex items-center space-x-1">
													<Calendar className="w-4 h-4" />
													<span>{new Date(assessment.created_at).toLocaleDateString()}</span>
												</div>
											</TableCell>
											<TableCell className="px-6 py-4 text-gray-500">
												{assessment.sections_count} sections, {assessment.questions_count} questions
											</TableCell>
											<TableCell className="px-6 py-4">
												<div className="flex items-center space-x-2">
													<button className="p-1.5 rounded-md hover:bg-blue-50 transition-colors group cursor-pointer">
														<Eye className="w-4 h-4 text-gray-600 group-hover:text-blue-600 cursor-pointer" />
													</button>
													<button 
														onClick={() => handleEditAssessment(assessment.id)}
														className="p-1.5 rounded-md hover:bg-green-50 transition-colors group cursor-pointer"
													>
														<Edit className="w-4 h-4 text-gray-600 group-hover:text-green-600 cursor-pointer" />
													</button>
													<button className="p-1.5 rounded-md hover:bg-red-50 transition-colors group cursor-pointer">
														<Trash2 className="w-4 h-4 text-gray-600 group-hover:text-red-600 cursor-pointer" />
													</button>
												</div>
											</TableCell>
										</TableRow>
									))
								)}
							</TableBody>
						</Table>
					</div>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app",
	Component: Homepage,
} as RouteObject;
