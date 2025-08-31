"use client";

import React, { useState, useEffect } from "react";
import { useNavigate, RouteObject } from "react-router";
import { Card, Table, TableHead, TableHeadCell, TableBody, TableRow, TableCell } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import RouteGuard from "../components/RouteGuard";
import {
	FileText,
	Clock,
	CheckCircle,
	Play,
	Edit,
	Calendar,
	BarChart3,
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";

// Interface for user assessments (same as in UserDashboard)
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

const UserAssessments: React.FC = () => {
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
			hour: "2-digit",
			minute: "2-digit",
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
						Start
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
							Edit
						</button>
					</div>
				);
			default:
				return null;
		}
	};

	return (
		<RouteGuard requireAdmin={false}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

				<DashboardLayout.Content>
					{/* Header */}
					<div className="mb-8">
						<h1 className="text-2xl font-bold text-gray-900">My Assessments</h1>
						<p className="text-gray-600 mt-1">Complete your assigned assessments and track your progress.</p>
					</div>

					{/* Assessments Grid */}
					<div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
						{loading ? (
							// Loading cards
							Array.from({ length: 6 }).map((_, index) => (
								<Card key={index} className="border border-gray-200 shadow-none animate-pulse">
									<div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
									<div className="h-3 bg-gray-200 rounded w-full mb-4"></div>
									<div className="h-2 bg-gray-200 rounded w-1/2 mb-4"></div>
									<div className="h-8 bg-gray-200 rounded w-20"></div>
								</Card>
							))
						) : (
							// Assessment cards
							assessments.map((assessment) => {
								const stateConfig = getStateDisplay(assessment.state);
								const StateIcon = stateConfig.icon;

								return (
									<Card key={assessment.id} className="border border-gray-200 shadow-none hover:shadow-lg transition-shadow">
										<div className="flex items-start justify-between mb-4">
											<div className="flex items-center space-x-3">
												<div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
													<FileText className="w-5 h-5 text-purple-600" />
												</div>
												<div className="flex-1 min-w-0">
													<h3 className="text-lg font-medium text-gray-900 truncate">
														{assessment.title}
													</h3>
													<span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${stateConfig.color}`}>
														<StateIcon className={`w-3 h-3 mr-1 ${stateConfig.iconColor}`} />
														{stateConfig.label}
													</span>
												</div>
											</div>
										</div>

										<p className="text-sm text-gray-600 mb-4 line-clamp-2">
											{assessment.description}
										</p>

										<div className="space-y-3">
											{/* Progress Bar */}
											<div>
												<div className="flex justify-between text-xs text-gray-600 mb-1">
													<span>Progress</span>
													<span>{assessment.progress_percentage}%</span>
												</div>
												<div className="w-full bg-gray-200 rounded-full h-2">
													<div 
														className="bg-purple-600 h-2 rounded-full transition-all duration-300" 
														style={{ width: `${assessment.progress_percentage}%` }}
													></div>
												</div>
											</div>

											{/* Metadata */}
											<div className="flex justify-between items-center text-xs text-gray-500">
												<span>{assessment.sections_count} sections</span>
												<span>{assessment.questions_count} questions</span>
											</div>


											{/* Action Button */}
											<div className="pt-2">
												{getActionButton(assessment)}
											</div>

											{/* Last Activity */}
											<div className="flex items-center text-xs text-gray-500 pt-1 border-t border-gray-100">
												<Calendar className="w-3 h-3 mr-1" />
												<span>
													{assessment.state === 'draft' ? 'Not started' : 
													 `Last activity: ${formatDate(assessment.completed_at || assessment.started_at)}`}
												</span>
											</div>
										</div>
									</Card>
								);
							})
						)}
					</div>

					{/* Empty State */}
					{!loading && assessments.length === 0 && (
						<div className="text-center py-12">
							<FileText className="w-16 h-16 text-gray-400 mx-auto mb-4" />
							<h3 className="text-lg font-medium text-gray-900 mb-2">No Assessments Available</h3>
							<p className="text-gray-500">You don't have any assessments assigned yet. Check back later!</p>
						</div>
					)}
				</DashboardLayout.Content>
			</DashboardLayout>
		</RouteGuard>
	);
};

export default UserAssessments;

export const routePath = {
	path: "/app/my-assessments",
	Component: UserAssessments,
} as RouteObject;