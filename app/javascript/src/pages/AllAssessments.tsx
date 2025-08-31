"use client";

import React, { useState, useEffect } from 'react';
import { RouteObject, useNavigate } from 'react-router';
import { Card, Table, TableBody, TableCell, TableHead, TableHeadCell, TableRow } from 'flowbite-react';
import { 
	FileText, 
	Plus, 
	Filter, 
	ArrowLeft,
	Eye,
	Edit,
	Share2,
	Trash2,
	Settings,
	X,
	Calendar,
	Users,
	BarChart3
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import DashboardLayout from '../layouts/DashboardLayout';
import ApplicationSidebar from '../components/Sidebar/Sidebar';
import { deleteAssessment } from '../api/assessments';

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
	const [activeFilter, setActiveFilter] = useState<'all' | 'active' | 'inactive'>('all');
	const [stats, setStats] = useState({ total: 0, active: 0, inactive: 0 });
	const [settingsModal, setSettingsModal] = useState<{ show: boolean; assessment: Assessment | null }>({ show: false, assessment: null });
	const [settingsForm, setSettingsForm] = useState({
		title: '',
		description: '',
		active: true,
		has_country_restrictions: false,
		restricted_countries: [] as string[]
	});

	useEffect(() => {
		fetchAssessments();
	}, [activeFilter]);

	const fetchAssessments = async () => {
		if (!token) return;

		try {
			setLoading(true);
			setError(null);

			const params = new URLSearchParams();
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

	const handleCopySurveyURL = async (assessmentId: number) => {
		const surveyURL = `${window.location.origin}/app/survey/${assessmentId}`;
		try {
			await navigator.clipboard.writeText(surveyURL);
			// You could add a toast notification here
		} catch (err) {
			console.error('Failed to copy URL:', err);
		}
	};

	const handleDeleteAssessment = async (id: number) => {
		if (!window.confirm('Are you sure you want to delete this assessment? This action cannot be undone.')) {
			return;
		}

		try {
			await deleteAssessment(id);
			
			// Remove from local state
			const deletedAssessment = assessments.find(a => a.id === id);
			setAssessments(assessments.filter(assessment => assessment.id !== id));
			
			// Update stats
			if (deletedAssessment) {
				setStats(prev => ({
					...prev,
					total: prev.total - 1,
					active: deletedAssessment.active ? prev.active - 1 : prev.active,
					inactive: deletedAssessment.active ? prev.inactive : prev.inactive - 1
				}));
			}
		} catch (err) {
			console.error('Delete error:', err);
			alert(err instanceof Error ? err.message : 'Failed to delete assessment');
		}
	};

	const handleOpenSettings = (assessment: Assessment) => {
		setSettingsForm({
			title: assessment.title,
			description: assessment.description,
			active: assessment.active,
			has_country_restrictions: assessment.has_country_restrictions,
			restricted_countries: assessment.restricted_countries
		});
		setSettingsModal({ show: true, assessment });
	};

	const handleCloseSettings = () => {
		setSettingsModal({ show: false, assessment: null });
	};

	const handleSaveSettings = async () => {
		if (!settingsModal.assessment || !token) return;

		try {
			const response = await fetch(`/api/v1/admin/assessments/${settingsModal.assessment.id}`, {
				method: 'PATCH',
				headers: {
					'Authorization': `Bearer ${token}`,
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					assessment: settingsForm
				}),
			});

			const result = await response.json();
			
			if (response.ok && result.status === 'ok') {
				// Update local state
				setAssessments(assessments.map(assessment => 
					assessment.id === settingsModal.assessment!.id 
						? { ...assessment, ...settingsForm }
						: assessment
				));
				handleCloseSettings();
			} else {
				alert(result.errors?.[0] || 'Failed to update assessment settings');
			}
		} catch (err) {
			console.error('Settings update error:', err);
			alert('Failed to update assessment settings');
		}
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
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors mr-4"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
							<div className="ml-2">
								<h1 className="text-2xl font-semibold text-gray-900">All Assessments</h1>
								<p className="text-gray-600 mt-1">Manage and monitor assessment performance</p>
							</div>
						</div>
						<button
							onClick={() => navigate('/app/assessments/new')}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
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

			{/* Filter */}
			<div className="flex justify-between items-center">
				<div className="flex items-center space-x-4">
					<div className="relative">
						<Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
						<select
							value={activeFilter}
							onChange={(e) => setActiveFilter(e.target.value as 'all' | 'active' | 'inactive')}
							className="pl-10 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 appearance-none bg-white text-sm"
						>
							<option value="all">All Status</option>
							<option value="active">Active Only</option>
							<option value="inactive">Inactive Only</option>
						</select>
					</div>
				</div>
			</div>

			{/* Assessments Table */}
			<div className="border border-gray-200 rounded-lg shadow-none bg-white">
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
							{activeFilter !== 'all' 
								? 'Try adjusting your filters'
								: 'Get started by creating your first assessment'
							}
						</p>
						{activeFilter === 'all' && (
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
						<Table className="min-w-full">
							<TableHead className="bg-gray-50">
								<TableHeadCell className="py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
									Assessment
								</TableHeadCell>
								<TableHeadCell className="py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
									Status
								</TableHeadCell>
								<TableHeadCell className="py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
									Structure
								</TableHeadCell>
								<TableHeadCell className="py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
									Created
								</TableHeadCell>
								<TableHeadCell className="py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
									Actions
								</TableHeadCell>
							</TableHead>
							<TableBody className="bg-white divide-y divide-gray-200">
								{assessments.map((assessment) => (
									<TableRow key={assessment.id} className="hover:bg-gray-50 transition-colors">
										<TableCell className="py-4 whitespace-nowrap">
											<div className="max-w-xs">
												<div className="text-sm font-medium text-gray-900 truncate">
													{assessment.title}
												</div>
												<div className="text-sm text-gray-500 truncate">
													{assessment.description}
												</div>
												{assessment.has_country_restrictions && (
													<span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800 mt-1">
														Restricted
													</span>
												)}
											</div>
										</TableCell>
										<TableCell className="py-4 whitespace-nowrap">
											<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
												assessment.active 
													? 'bg-green-100 text-green-800'
													: 'bg-gray-100 text-gray-800'
											}`}>
												{assessment.active ? 'Active' : 'Inactive'}
											</span>
										</TableCell>
										<TableCell className="py-4 whitespace-nowrap">
											<div className="flex items-center space-x-4 text-sm text-gray-900">
												<div className="flex items-center">
													<FileText className="w-4 h-4 mr-1 text-gray-400" />
													<span>{assessment.sections_count} sections</span>
												</div>
												<div className="flex items-center">
													<Users className="w-4 h-4 mr-1 text-gray-400" />
													<span>{assessment.questions_count} questions</span>
												</div>
											</div>
										</TableCell>
										<TableCell className="py-4 whitespace-nowrap text-sm text-gray-500">
											{formatDate(assessment.created_at)}
										</TableCell>
										<TableCell className="py-4 whitespace-nowrap">
											<div className="flex items-center space-x-2">
												<button
													onClick={() => handleViewAssessment(assessment.id)}
													className="p-1.5 rounded-md hover:bg-gray-100 transition-colors group cursor-pointer"
													title="View Assessment"
												>
													<Eye className="w-4 h-4 text-gray-600 cursor-pointer" />
												</button>
												<button
													onClick={() => handleEditAssessment(assessment.id)}
													className="p-1.5 rounded-md hover:bg-gray-100 transition-colors group cursor-pointer"
													title="Edit Assessment"
												>
													<Edit className="w-4 h-4 text-gray-600 cursor-pointer" />
												</button>
												<button
													onClick={() => handleOpenSettings(assessment)}
													className="p-1.5 rounded-md hover:bg-gray-100 transition-colors group cursor-pointer"
													title="Assessment Settings"
												>
													<Settings className="w-4 h-4 text-gray-600 cursor-pointer" />
												</button>
												<button
													onClick={() => handleCopySurveyURL(assessment.id)}
													className="p-1.5 rounded-md hover:bg-gray-100 transition-colors group cursor-pointer"
													title="Share Survey Link"
												>
													<Share2 className="w-4 h-4 text-gray-600 cursor-pointer" />
												</button>
												<button
													onClick={() => handleDeleteAssessment(assessment.id)}
													className="p-1.5 rounded-md hover:bg-gray-100 transition-colors group cursor-pointer"
													title="Delete Assessment"
												>
													<Trash2 className="w-4 h-4 text-gray-600 cursor-pointer" />
												</button>
											</div>
										</TableCell>
									</TableRow>
								))}
							</TableBody>
						</Table>
					</div>
				)}
			</div>

			{/* Settings Modal */}
			{settingsModal.show && (
				<div className="fixed inset-0 z-50 flex items-center justify-center p-4">
					{/* Background overlay */}
					<div 
						className="absolute inset-0 bg-gray-500/30"
						onClick={handleCloseSettings}
					></div>

					{/* Modal panel */}
					<div className="relative bg-white rounded-lg shadow-xl max-w-lg w-full max-h-screen overflow-y-auto">
							{/* Header */}
							<div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
								<div className="flex justify-between items-center mb-4">
									<h3 className="text-lg font-medium text-gray-900">
										Assessment Settings - {settingsModal.assessment?.title}
									</h3>
									<button
										onClick={handleCloseSettings}
										className="text-gray-400 hover:text-gray-600"
									>
										<X className="w-5 h-5" />
									</button>
								</div>

								{/* Body */}
								<div className="space-y-4">
									{/* Title */}
									<div>
										<label className="block text-sm font-medium text-gray-700 mb-1">
											Title
										</label>
										<input
											type="text"
											value={settingsForm.title}
											onChange={(e) => setSettingsForm({ ...settingsForm, title: e.target.value })}
											placeholder="Assessment title"
											className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
										/>
									</div>

									{/* Description */}
									<div>
										<label className="block text-sm font-medium text-gray-700 mb-1">
											Description
										</label>
										<textarea
											rows={3}
											value={settingsForm.description}
											onChange={(e) => setSettingsForm({ ...settingsForm, description: e.target.value })}
											placeholder="Assessment description"
											className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
										/>
									</div>

									{/* Active Status */}
									<div className="flex items-center space-x-2">
										<input
											type="checkbox"
											checked={settingsForm.active}
											onChange={(e) => setSettingsForm({ ...settingsForm, active: e.target.checked })}
											className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
										/>
										<label className="text-sm font-medium text-gray-700">
											Active (users can take this assessment)
										</label>
									</div>

									{/* Country Restrictions */}
									<div className="space-y-2">
										<div className="flex items-center space-x-2">
											<input
												type="checkbox"
												checked={settingsForm.has_country_restrictions}
												onChange={(e) => setSettingsForm({ 
													...settingsForm, 
													has_country_restrictions: e.target.checked,
													restricted_countries: e.target.checked ? settingsForm.restricted_countries : []
												})}
												className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
											/>
											<label className="text-sm font-medium text-gray-700">
												Enable country restrictions
											</label>
										</div>
										
										{settingsForm.has_country_restrictions && (
											<div className="ml-6">
												<label className="block text-sm text-gray-600 mb-1">
													Restricted Countries (comma-separated country codes)
												</label>
												<input
													type="text"
													value={settingsForm.restricted_countries.join(', ')}
													onChange={(e) => setSettingsForm({ 
														...settingsForm, 
														restricted_countries: e.target.value.split(',').map(c => c.trim()).filter(c => c)
													})}
													placeholder="e.g., US, CA, UK"
													className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
												/>
												<p className="text-xs text-gray-500 mt-1">
													Users from these countries will not be able to access this assessment
												</p>
											</div>
										)}
									</div>
								</div>
							</div>

						{/* Footer */}
						<div className="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
							<button
								onClick={handleCloseSettings}
								className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
							>
								Cancel
							</button>
							<button
								onClick={handleSaveSettings}
								className="px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-transparent rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
							>
								Save Settings
							</button>
						</div>
					</div>
				</div>
			)}
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments",
	Component: AllAssessments,
} as RouteObject;