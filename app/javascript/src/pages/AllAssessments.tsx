"use client";

import React, { useState, useEffect } from 'react';
import { RouteObject, useNavigate } from 'react-router';
import { Card, Table, TableBody, TableCell, TableHead, TableHeadCell, TableRow } from 'flowbite-react';
import { 
	FileText, 
	Plus, 
	Search, 
	Filter, 
	ArrowLeft,
	Eye,
	Edit,
	Trash2,
	MoreHorizontal,
	Calendar,
	Users,
	BarChart3
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import DashboardLayout from '../layouts/DashboardLayout';
import ApplicationSidebar from '../components/Sidebar/Sidebar';

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

interface AssessmentsData {
	assessments: Assessment[];
	total_count: number;
	active_count: number;
	inactive_count: number;
}

function AllAssessments() {
	const { token } = useAuth();
	const navigate = useNavigate();
	const [assessments, setAssessments] = useState<Assessment[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [searchTerm, setSearchTerm] = useState('');
	const [activeFilter, setActiveFilter] = useState<'all' | 'active' | 'inactive'>('all');
	const [stats, setStats] = useState({ total: 0, active: 0, inactive: 0 });

	useEffect(() => {
		fetchAssessments();
	}, [searchTerm, activeFilter]);

	const fetchAssessments = async () => {
		if (!token) return;

		try {
			setLoading(true);
			setError(null);

			const params = new URLSearchParams();
			if (searchTerm) params.append('search', searchTerm);
			if (activeFilter !== 'all') {
				params.append('active', activeFilter === 'active' ? 'true' : 'false');
			}

			const response = await fetch(`/api/v1/admin/assessments?${params}`, {
				headers: {
					'Authorization': `Bearer ${token}`,
					'Content-Type': 'application/json',
				},
			});

			const result = await response.json();

			if (result.status === 'ok') {
				const data: AssessmentsData = result.data;
				setAssessments(data.assessments || []);
				setStats({
					total: data.total_count || 0,
					active: data.active_count || 0,
					inactive: data.inactive_count || 0
				});
			} else {
				let errorMessage = 'Failed to fetch assessments';
				
				if (result.errors && Array.isArray(result.errors) && result.errors.length > 0) {
					const firstError = result.errors[0];
					if (typeof firstError === 'string') {
						errorMessage = firstError;
					} else if (firstError && typeof firstError === 'object' && firstError.message) {
						errorMessage = firstError.message;
					}
				}
				
				setError(errorMessage);
			}
		} catch (err) {
			console.error('Assessments fetch error:', err);
			setError(err instanceof Error ? err.message : 'Failed to load assessments');
		} finally {
			setLoading(false);
		}
	};

	const formatDate = (dateString: string) => {
		return new Date(dateString).toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	};

	const handleViewAssessment = (id: number) => {
		navigate(`/app/assessments/${id}/preview`);
	};

	const handleEditAssessment = (id: number) => {
		navigate(`/app/assessments/${id}/sections`);
	};

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				<div className="space-y-6">
					{/* Header */}
					<div className="flex items-center justify-between">
						<div className="flex items-center">
							<button
								onClick={() => navigate('/app')}
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors mr-3"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
							<div>
								<h1 className="text-2xl font-semibold text-gray-900">All Assessments</h1>
								<p className="text-gray-600 mt-1">Manage and monitor assessment performance</p>
							</div>
						</div>
						<button
							onClick={() => navigate('/app/assessments/new')}
							className="flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
						>
							<Plus className="w-4 h-4 mr-2" />
							New Assessment
						</button>
					</div>

			{/* Stats Cards */}
			<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-blue-100">
							<FileText className="w-6 h-6 text-blue-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Total Assessments</p>
							<p className="text-2xl font-semibold text-gray-900">{stats.total}</p>
						</div>
					</div>
				</Card>
				
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-green-100">
							<BarChart3 className="w-6 h-6 text-green-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Active</p>
							<p className="text-2xl font-semibold text-gray-900">{stats.active}</p>
						</div>
					</div>
				</Card>

				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-gray-100">
							<Calendar className="w-6 h-6 text-gray-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Inactive</p>
							<p className="text-2xl font-semibold text-gray-900">{stats.inactive}</p>
						</div>
					</div>
				</Card>
			</div>

			{/* Filters */}
			<Card className="border border-gray-200 shadow-none">
				<div className="flex flex-col sm:flex-row gap-4">
					{/* Search */}
					<div className="relative flex-1">
						<Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
						<input
							type="text"
							placeholder="Search assessments..."
							value={searchTerm}
							onChange={(e) => setSearchTerm(e.target.value)}
							className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
						/>
					</div>

					{/* Status Filter */}
					<div className="relative">
						<Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
						<select
							value={activeFilter}
							onChange={(e) => setActiveFilter(e.target.value as 'all' | 'active' | 'inactive')}
							className="pl-10 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 appearance-none bg-white"
						>
							<option value="all">All Status</option>
							<option value="active">Active Only</option>
							<option value="inactive">Inactive Only</option>
						</select>
					</div>
				</div>
			</Card>

			{/* Assessments Table */}
			<Card className="border border-gray-200 shadow-none">
				{loading ? (
					<div className="flex items-center justify-center h-32">
						<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
					</div>
				) : error ? (
					<div className="flex items-center justify-center h-32 text-red-600">
						<p>{error}</p>
					</div>
				) : assessments.length === 0 ? (
					<div className="text-center py-12">
						<FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
						<h3 className="text-lg font-medium text-gray-900 mb-2">No assessments found</h3>
						<p className="text-gray-500 mb-6">
							{searchTerm || activeFilter !== 'all' 
								? 'Try adjusting your search or filters'
								: 'Get started by creating your first assessment'
							}
						</p>
						{!searchTerm && activeFilter === 'all' && (
							<button
								onClick={() => navigate('/app/assessments/new')}
								className="flex items-center mx-auto px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
							>
								<Plus className="w-4 h-4 mr-2" />
								Create Assessment
							</button>
						)}
					</div>
				) : (
					<div className="overflow-x-auto">
						<Table>
							<TableHead>
								<TableHeadCell>Assessment</TableHeadCell>
								<TableHeadCell>Status</TableHeadCell>
								<TableHeadCell>Questions</TableHeadCell>
								<TableHeadCell>Sections</TableHeadCell>
								<TableHeadCell>Created</TableHeadCell>
								<TableHeadCell>Actions</TableHeadCell>
							</TableHead>
							<TableBody className="divide-y">
								{assessments.map((assessment) => (
									<TableRow key={assessment.id} className="bg-white">
										<TableCell>
											<div>
												<div className="font-medium text-gray-900">{assessment.title}</div>
												<div className="text-sm text-gray-500 max-w-xs truncate">
													{assessment.description}
												</div>
												{assessment.has_country_restrictions && (
													<div className="text-xs text-orange-600 mt-1">
														Country restrictions applied
													</div>
												)}
											</div>
										</TableCell>
										<TableCell>
											<span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
												assessment.active 
													? 'bg-green-100 text-green-800'
													: 'bg-gray-100 text-gray-800'
											}`}>
												{assessment.active ? 'Active' : 'Inactive'}
											</span>
										</TableCell>
										<TableCell>
											<div className="flex items-center text-sm text-gray-900">
												<Users className="w-4 h-4 mr-1 text-gray-400" />
												{assessment.questions_count}
											</div>
										</TableCell>
										<TableCell>
											<div className="flex items-center text-sm text-gray-900">
												<FileText className="w-4 h-4 mr-1 text-gray-400" />
												{assessment.sections_count}
											</div>
										</TableCell>
										<TableCell className="text-sm text-gray-500">
											{formatDate(assessment.created_at)}
										</TableCell>
										<TableCell>
											<div className="flex items-center space-x-2">
												<button
													onClick={() => handleViewAssessment(assessment.id)}
													className="p-1.5 rounded-md hover:bg-blue-50 transition-colors group cursor-pointer"
													title="View Assessment"
												>
													<Eye className="w-4 h-4 text-gray-600 group-hover:text-blue-600 cursor-pointer" />
												</button>
												<button
													onClick={() => handleEditAssessment(assessment.id)}
													className="p-1.5 rounded-md hover:bg-green-50 transition-colors group cursor-pointer"
													title="Edit Assessment"
												>
													<Edit className="w-4 h-4 text-gray-600 group-hover:text-green-600 cursor-pointer" />
												</button>
												<button
													className="p-1.5 rounded-md hover:bg-red-50 transition-colors group cursor-pointer"
													title="More Options"
												>
													<MoreHorizontal className="w-4 h-4 text-gray-600 group-hover:text-red-600 cursor-pointer" />
												</button>
											</div>
										</TableCell>
									</TableRow>
								))}
							</TableBody>
						</Table>
					</div>
				)}
			</Card>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments",
	Component: AllAssessments,
} as RouteObject;