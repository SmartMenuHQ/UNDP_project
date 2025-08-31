"use client";

import React, { useState, useEffect } from "react";
import { useNavigate, RouteObject } from "react-router";
import { Card, Table, TableHead, TableHeadCell, TableBody, TableRow, TableCell, Badge } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import {
	FileText,
	Clock,
	CheckCircle,
	Play,
	Edit,
	Calendar,
	User,
	BarChart3,
	Target,
	AlertCircle,
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";

// Static data for user assessments based on Swagger docs
interface UserAssessment {
	id: number;
	assessment_id: number;
	title: string;
	description: string;
	state: 'draft' | 'in_progress' | 'completed' | 'submitted';
	progress_percentage: number;
	started_at?: string;
	completed_at?: string;
	submitted_at?: string;
	total_score?: number;
	max_possible_score?: number;
	grade?: string;
	sections_count: number;
	questions_count: number;
	current_section_id?: number;
	current_question_id?: number;
}

const getUserAssessments = (userId: string): UserAssessment[] => {
	return [
		{
			id: 1,
			assessment_id: 1,
			title: "Global Technology Survey",
			description: "A comprehensive survey about technology usage and preferences across different regions.",
			state: 'in_progress',
			progress_percentage: 65,
			started_at: "2024-12-01T14:15:00.000Z",
			sections_count: 3,
			questions_count: 12,
			current_section_id: 2,
			current_question_id: 8,
			max_possible_score: 100
		},
		{
			id: 2,
			assessment_id: 2,
			title: "Business Impact Assessment",
			description: "Comprehensive evaluation of business sustainability and social impact.",
			state: 'completed',
			progress_percentage: 100,
			started_at: "2024-11-15T10:30:00.000Z",
			completed_at: "2024-11-15T11:45:00.000Z",
			submitted_at: "2024-11-15T11:45:00.000Z",
			total_score: 85,
			max_possible_score: 100,
			grade: "B+",
			sections_count: 4,
			questions_count: 20
		},
		{
			id: 3,
			assessment_id: 3,
			title: "Digital Transformation Readiness",
			description: "Evaluation of digital capabilities and transformation readiness.",
			state: 'draft',
			progress_percentage: 0,
			sections_count: 5,
			questions_count: 25,
			max_possible_score: 100
		},
		{
			id: 4,
			assessment_id: 4,
			title: "Supply Chain Resilience",
			description: "Assessment of supply chain sustainability and risk management.",
			state: 'completed',
			progress_percentage: 100,
			started_at: "2024-10-25T09:00:00.000Z",
			completed_at: "2024-10-25T10:30:00.000Z",
			submitted_at: "2024-10-25T10:30:00.000Z",
			total_score: 92,
			max_possible_score: 100,
			grade: "A-",
			sections_count: 3,
			questions_count: 15
		},
		{
			id: 5,
			assessment_id: 5,
			title: "Environmental Compliance Survey",
			description: "Assessment of environmental policies and compliance measures.",
			state: 'in_progress',
			progress_percentage: 40,
			started_at: "2024-12-05T16:00:00.000Z",
			sections_count: 4,
			questions_count: 18,
			current_section_id: 2,
			current_question_id: 7,
			max_possible_score: 100
		}
	];
};

const UserDashboard: React.FC = () => {
	const navigate = useNavigate();
	const { user } = useAuth();
	const [assessments, setAssessments] = useState<UserAssessment[]>([]);
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		// Simulate loading assessments
		setTimeout(() => {
			const userAssessments = getUserAssessments(user?.user?.id?.toString() || "1");
			setAssessments(userAssessments);
			setLoading(false);
		}, 500);
	}, [user]);

	const formatDate = (dateString: string | undefined) => {
		if (!dateString) return "Not started";
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "short",
			day: "numeric",
		});
	};

	const getStateDisplay = (state: string) => {
		const states = {
			draft: { 
				color: "bg-gray-100 text-gray-800", 
				label: "Not Started", 
				icon: Clock,
				iconColor: "text-gray-600"
			},
			in_progress: { 
				color: "bg-blue-100 text-blue-800", 
				label: "In Progress", 
				icon: Play,
				iconColor: "text-blue-600"
			},
			completed: { 
				color: "bg-green-100 text-green-800", 
				label: "Completed", 
				icon: CheckCircle,
				iconColor: "text-green-600"
			},
			submitted: { 
				color: "bg-purple-100 text-purple-800", 
				label: "Submitted", 
				icon: CheckCircle,
				iconColor: "text-purple-600"
			}
		};

		return states[state as keyof typeof states] || states.draft;
	};

	const handleStartAssessment = (assessment: UserAssessment) => {
		if (assessment.state === 'draft') {
			navigate(`/app/assessments/${assessment.assessment_id}/start`);
		} else {
			navigate(`/app/assessments/${assessment.assessment_id}/continue`);
		}
	};

	const handleEditResponses = (assessment: UserAssessment) => {
		navigate(`/app/assessments/${assessment.assessment_id}/responses/${assessment.id}/edit`);
	};

	const getActionButton = (assessment: UserAssessment) => {
		switch (assessment.state) {
			case 'draft':
				return (
					<button
						onClick={() => handleStartAssessment(assessment)}
						className="flex items-center px-3 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
					>
						<Play className="w-4 h-4 mr-2" />
						Start Assessment
					</button>
				);
			case 'in_progress':
				return (
					<div className="flex space-x-2">
						<button
							onClick={() => handleStartAssessment(assessment)}
							className="flex items-center px-3 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
						>
							<Play className="w-4 h-4 mr-2" />
							Continue
						</button>
					</div>
				);
			case 'completed':
			case 'submitted':
				return (
					<div className="flex space-x-2">
						<button
							onClick={() => handleEditResponses(assessment)}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<Edit className="w-4 h-4 mr-2" />
							Edit Responses
						</button>
					</div>
				);
			default:
				return null;
		}
	};

	// Calculate statistics
	const stats = {
		total: assessments.length,
		completed: assessments.filter(a => a.state === 'completed' || a.state === 'submitted').length,
		in_progress: assessments.filter(a => a.state === 'in_progress').length
	};

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				{/* Header */}
				<div className="mb-8">
					<h1 className="text-2xl font-bold text-gray-900">My Assessments</h1>
					<p className="text-gray-600 mt-1">View and manage your assigned assessments.</p>
				</div>

				{/* Statistics Cards */}
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-purple-100 mr-4">
								<FileText className="w-6 h-6 text-purple-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Total Assessments</p>
								<p className="text-2xl font-medium text-gray-900">{stats.total}</p>
							</div>
						</div>
					</div>

					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-green-100 mr-4">
								<CheckCircle className="w-6 h-6 text-green-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Completed</p>
								<p className="text-2xl font-medium text-gray-900">{stats.completed}</p>
							</div>
						</div>
					</div>

					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-blue-100 mr-4">
								<Play className="w-6 h-6 text-blue-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">In Progress</p>
								<p className="text-2xl font-medium text-gray-900">{stats.in_progress}</p>
							</div>
						</div>
					</div>

				</div>

				{/* Assessments Table */}
				<div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
					<div className="px-6 py-4 border-b border-gray-200">
						<h3 className="text-lg font-medium text-gray-900">Your Assessments</h3>
					</div>

					{loading ? (
						<div className="p-8 text-center">
							<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto mb-4"></div>
							<p className="text-gray-500">Loading assessments...</p>
						</div>
					) : (
						<div className="overflow-x-auto">
							<Table hoverable>
								<TableHead>
									<TableHeadCell>Assessment</TableHeadCell>
									<TableHeadCell>Status</TableHeadCell>
									<TableHeadCell>Progress</TableHeadCell>
									<TableHeadCell>Last Activity</TableHeadCell>
									<TableHeadCell>Actions</TableHeadCell>
								</TableHead>
								<TableBody>
									{assessments.map((assessment) => {
										const stateConfig = getStateDisplay(assessment.state);
										const StateIcon = stateConfig.icon;

										return (
											<TableRow key={assessment.id} className="bg-white hover:bg-gray-50 transition-colors">
												<TableCell className="font-medium">
													<div className="flex items-center space-x-3">
														<div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
															<FileText className="w-4 h-4 text-purple-600" />
														</div>
														<div>
															<div className="font-semibold text-gray-900">
																{assessment.title}
															</div>
															<div className="text-sm text-gray-500">
																{assessment.sections_count} sections, {assessment.questions_count} questions
															</div>
														</div>
													</div>
												</TableCell>

												<TableCell>
													<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium whitespace-nowrap ${stateConfig.color}`}>
														<StateIcon className={`w-3 h-3 mr-1 ${stateConfig.iconColor}`} />
														{stateConfig.label}
													</span>
												</TableCell>

												<TableCell>
													<div className="flex items-center space-x-3">
														<div className="flex-1 bg-gray-200 rounded-full h-2">
															<div 
																className="bg-purple-600 h-2 rounded-full" 
																style={{ width: `${assessment.progress_percentage}%` }}
															></div>
														</div>
														<span className="text-sm font-medium text-gray-900 min-w-0">
															{assessment.progress_percentage}%
														</span>
													</div>
												</TableCell>


												<TableCell>
													<div className="text-sm text-gray-900">
														{formatDate(assessment.completed_at || assessment.started_at)}
													</div>
												</TableCell>

												<TableCell>
													{getActionButton(assessment)}
												</TableCell>
											</TableRow>
										);
									})}
								</TableBody>
							</Table>
						</div>
					)}
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
};

export default UserDashboard;

export const routePath = {
	path: "/app/dashboard",
	Component: UserDashboard,
} as RouteObject;