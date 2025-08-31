"use client";

import React from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import { Card, Table, TableHead, TableHeadCell, TableBody, TableRow, TableCell, Badge } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import RouteGuard from "../components/RouteGuard";
import {
	ArrowLeft,
	Building2,
	User,
	Mail,
	Globe,
	Calendar,
	Activity,
	TrendingUp,
	FileText,
	CheckCircle,
	Clock,
	Star,
	BarChart3,
	Target,
	Award,
	Shield,
	AlertCircle,
	XCircle,
} from "lucide-react";

// Static data for business detail based on Swagger docs
const getBusinessById = (id: string) => {
	const businesses = {
		"232": {
			id: 232,
			email_address: "willie@schuster-barton.example",
			first_name: "Effie",
			last_name: "Marks",
			full_name: "Effie Marks",
			display_name: "Effie Marks",
			admin: false,
			profile_completed: true,
			default_language: "en",
			country: {
				id: 210,
				name: "United States",
				code: "USA"
			},
			created_at: "2024-11-15T08:13:36.552Z",
			updated_at: "2024-12-10T08:13:36.552Z",
		},
		"233": {
			id: 233,
			email_address: "rosalina.koch@hand.test",
			first_name: "Lewis",
			last_name: "Haley",
			full_name: "Lewis Haley",
			display_name: "Lewis Haley",
			admin: false,
			profile_completed: true,
			default_language: "en",
			country: {
				id: 211,
				name: "China",
				code: "CHN"
			},
			created_at: "2024-10-20T08:13:36.552Z",
			updated_at: "2024-12-08T14:22:10.330Z",
		}
	};
	return businesses[id as keyof typeof businesses] || businesses["232"];
};

// Static assessment response sessions based on Swagger docs
const getBusinessAssessments = (businessId: string) => {
	return [
		{
			id: 2,
			state: "completed",
			respondent_name: "Lewis Haley",
			started_at: "2024-11-15T10:30:00.000Z",
			completed_at: "2024-11-15T11:45:00.000Z",
			submitted_at: "2024-11-15T11:45:00.000Z",
			marked_at: "2024-11-16T09:20:00.000Z",
			total_score: 85.0,
			max_possible_score: 100.0,
			grade: "B+",
			assessment: {
				id: 1,
				title: "Business Impact Assessment",
				description: "Comprehensive evaluation of business sustainability and social impact"
			},
			created_at: "2024-11-15T10:00:00.000Z",
			updated_at: "2024-11-16T09:20:00.000Z"
		},
		{
			id: 4,
			state: "in_progress",
			respondent_name: "Lewis Haley",
			started_at: "2024-12-01T14:15:00.000Z",
			completed_at: null,
			submitted_at: null,
			marked_at: null,
			total_score: 0.0,
			max_possible_score: 100.0,
			grade: null,
			assessment: {
				id: 3,
				title: "Environmental Compliance Survey",
				description: "Assessment of environmental policies and compliance measures"
			},
			created_at: "2024-12-01T14:00:00.000Z",
			updated_at: "2024-12-08T16:30:00.000Z"
		},
		{
			id: 7,
			state: "completed",
			respondent_name: "Lewis Haley",
			started_at: "2024-10-25T09:00:00.000Z",
			completed_at: "2024-10-25T10:30:00.000Z",
			submitted_at: "2024-10-25T10:30:00.000Z",
			marked_at: "2024-10-26T11:15:00.000Z",
			total_score: 92.5,
			max_possible_score: 100.0,
			grade: "A-",
			assessment: {
				id: 2,
				title: "Digital Transformation Readiness",
				description: "Evaluation of digital capabilities and transformation readiness"
			},
			created_at: "2024-10-25T08:45:00.000Z",
			updated_at: "2024-10-26T11:15:00.000Z"
		},
		{
			id: 12,
			state: "draft",
			respondent_name: "Lewis Haley",
			started_at: null,
			completed_at: null,
			submitted_at: null,
			marked_at: null,
			total_score: 0.0,
			max_possible_score: 100.0,
			grade: null,
			assessment: {
				id: 5,
				title: "Financial Health Check",
				description: "Assessment of financial stability and growth potential"
			},
			created_at: "2024-12-10T13:20:00.000Z",
			updated_at: "2024-12-10T13:20:00.000Z"
		},
		{
			id: 15,
			state: "completed",
			respondent_name: "Lewis Haley",
			started_at: "2024-09-20T16:00:00.000Z",
			completed_at: "2024-09-20T17:15:00.000Z",
			submitted_at: "2024-09-20T17:15:00.000Z",
			marked_at: "2024-09-21T10:30:00.000Z",
			total_score: 78.0,
			max_possible_score: 100.0,
			grade: "B",
			assessment: {
				id: 4,
				title: "Supply Chain Resilience",
				description: "Evaluation of supply chain sustainability and risk management"
			},
			created_at: "2024-09-20T15:45:00.000Z",
			updated_at: "2024-09-21T10:30:00.000Z"
		}
	];
};

// Static business statistics
const getBusinessStats = (businessId: string) => {
	const assessments = getBusinessAssessments(businessId);
	const completed = assessments.filter(a => a.state === "completed");
	const totalScore = completed.reduce((sum, a) => sum + a.total_score, 0);
	
	return {
		total_sessions: assessments.length,
		completed_sessions: completed.length,
		completion_rate: Math.round((completed.length / assessments.length) * 100),
		average_score: completed.length > 0 ? Math.round(totalScore / completed.length) : null,
		latest_activity: assessments[0]?.updated_at || null,
		assessments_taken: new Set(assessments.map(a => a.assessment.id)).size
	};
};

// Business Readiness Classification Functions
const getExportReadinessTier = (score: number | null) => {
	if (score === null) return null;
	
	if (score >= 55) {
		return {
			tier: "Export/Import Ready",
			description: "Strong export readiness and infrastructure",
			color: "text-green-700 bg-green-50 border-green-200",
			icon: Shield,
			iconColor: "text-green-600",
			details: [
				"Strong export readiness and infrastructure",
				"Proven AfCFTA compliance",
				"Robust digital/IP assets",
				"Investment matching readiness"
			],
			remarks: "High export- and investment-readiness; ready to match with investors and businesses abroad."
		};
	} else if (score >= 30) {
		return {
			tier: "Almost Ready",
			description: "Moderate gaps in export readiness",
			color: "text-amber-700 bg-amber-50 border-amber-200",
			icon: AlertCircle,
			iconColor: "text-amber-600",
			details: [
				"Moderate gaps in export readiness and investment readiness",
				"Requires targeted training"
			],
			remarks: "Almost ready to export, invest, and engage in cross-border matching."
		};
	} else {
		return {
			tier: "Not Ready",
			description: "Limited export capacity",
			color: "text-red-700 bg-red-50 border-red-200",
			icon: XCircle,
			iconColor: "text-red-600",
			details: [
				"Limited export capacity and infrastructure",
				"Needs foundational support (e.g., business planning, AfCFTA education)"
			],
			remarks: "Not ready to export or match."
		};
	}
};

const getBusinessClassification = (score: number | null, businessType: 'products' | 'services' = 'products') => {
	if (score === null) return null;
	
	const thresholds = businessType === 'products' 
		? { classA: 60, classB: 45 }
		: { classA: 49, classB: 34 };
	
	if (score > thresholds.classA) {
		return {
			class: "Class A",
			description: "Fully ready for UNDP initiatives",
			color: "text-green-700 bg-green-50 border-green-200",
			icon: Award,
			iconColor: "text-green-600",
			remarks: "Fully ready to participate in UNDP initiatives such as IATF and B2B events."
		};
	} else if (score >= thresholds.classB) {
		return {
			class: "Class B",
			description: "Committed but needs extra support",
			color: "text-blue-700 bg-blue-50 border-blue-200",
			icon: Target,
			iconColor: "text-blue-600",
			remarks: "Committed to AfCFTA but require extra support and trading experience."
		};
	} else {
		return {
			class: "Class C",
			description: "Requires national-level support",
			color: "text-purple-700 bg-purple-50 border-purple-200",
			icon: Building2,
			iconColor: "text-purple-600",
			remarks: "Require national-level support before engaging in cross-border trade."
		};
	}
};

const BusinessDetail: React.FC = () => {
	const { id } = useParams<{ id: string }>();
	const navigate = useNavigate();
	
	if (!id) {
		navigate("/app/businesses");
		return null;
	}

	const business = getBusinessById(id);
	const assessments = getBusinessAssessments(id);
	const statistics = getBusinessStats(id);
	
	// Get readiness classifications based on average score
	const exportReadiness = getExportReadinessTier(statistics.average_score);
	const businessClassification = getBusinessClassification(statistics.average_score, 'products'); // Default to products, could be dynamic

	const formatDate = (dateString: string | null) => {
		if (!dateString) return "Not available";
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "short",
			day: "numeric",
			hour: "2-digit",
			minute: "2-digit",
		});
	};

	const formatDateShort = (dateString: string | null) => {
		if (!dateString) return "Not available";
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "short",
			day: "numeric",
		});
	};

	const getStateDisplay = (state: string) => {
		const states = {
			draft: { color: "gray", label: "Draft", icon: Clock },
			in_progress: { color: "warning", label: "In Progress", icon: Activity },
			completed: { color: "info", label: "Completed", icon: CheckCircle },
			marked: { color: "success", label: "Marked", icon: Star },
		};

		return states[state as keyof typeof states] || {
			color: "gray",
			label: state,
			icon: Clock,
		};
	};

	const getScoreColor = (percentage: number | null) => {
		if (percentage === null) return "text-gray-400";
		if (percentage >= 90) return "text-green-600";
		if (percentage >= 80) return "text-blue-600";
		if (percentage >= 70) return "text-yellow-600";
		return "text-red-600";
	};

	const getGradeIcon = (grade: string | null) => {
		if (!grade) return Star;
		if (grade.startsWith("A")) return Award;
		if (grade.startsWith("B")) return Target;
		return Star;
	};

	return (
		<RouteGuard requireAdmin={true}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				{/* Header */}
				<div className="flex items-center justify-between mb-8">
					<div className="flex items-center space-x-4">
						<button
							onClick={() => navigate("/app/businesses")}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<ArrowLeft className="w-4 h-4 mr-2" />
							Back
						</button>
						<h1 className="text-2xl font-medium text-gray-900">{business.display_name}</h1>
					</div>
				</div>

				{/* Business Info and Stats Cards */}
				<div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
					{/* Business Info Card */}
					<div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
						<h3 className="text-lg font-medium text-gray-900 mb-6 flex items-center">
							<User className="w-5 h-5 mr-2 text-blue-600" />
							Business Information
						</h3>
						<div className="space-y-6">
							<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
								<div>
									<div className="text-sm text-gray-600 mb-2">Full Name</div>
									<div className="text-lg font-medium text-gray-900">{business.full_name}</div>
								</div>
								<div>
									<div className="text-sm text-gray-600 mb-2">Email Address</div>
									<div className="flex items-center text-gray-900">
										<Mail className="w-4 h-4 mr-2 text-gray-400" />
										<span>{business.email_address}</span>
									</div>
								</div>
							</div>
							<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
								<div>
									<div className="text-sm text-gray-600 mb-2">Country</div>
									<div className="flex items-center">
										<Globe className="w-4 h-4 mr-2 text-gray-400" />
										<span className="text-gray-900 mr-2">{business.country.name}</span>
										<span className="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-600 rounded-full">
											{business.country.code}
										</span>
									</div>
								</div>
								<div>
									<div className="text-sm text-gray-600 mb-2">Registration Date</div>
									<div className="flex items-center text-gray-900">
										<Calendar className="w-4 h-4 mr-2 text-gray-400" />
										<span>{formatDateShort(business.created_at)}</span>
									</div>
								</div>
							</div>
						</div>
					</div>

					{/* Statistics Panel */}
					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
							<BarChart3 className="w-5 h-5 mr-2 text-blue-600" />
							Assessment Analytics
						</h3>
						<div className="space-y-4">
							<div className="flex justify-between items-center py-2 border-b border-gray-100">
								<span className="text-sm text-gray-600">Total Sessions</span>
								<span className="font-semibold text-gray-900">{statistics.total_sessions}</span>
							</div>
							<div className="flex justify-between items-center py-2 border-b border-gray-100">
								<span className="text-sm text-gray-600">Completed</span>
								<span className="font-semibold text-gray-900">{statistics.completed_sessions}</span>
							</div>
							<div className="flex justify-between items-center py-2 border-b border-gray-100">
								<span className="text-sm text-gray-600">Completion Rate</span>
								<span className="font-semibold text-green-600">{statistics.completion_rate}%</span>
							</div>
							<div className="flex justify-between items-center py-2 border-b border-gray-100">
								<span className="text-sm text-gray-600">Average Score</span>
								<span className={`font-semibold ${getScoreColor(statistics.average_score)}`}>
									{statistics.average_score ? `${statistics.average_score}%` : "N/A"}
								</span>
							</div>
							<div className="flex justify-between items-center py-2 border-b border-gray-100">
								<span className="text-sm text-gray-600">Unique Assessments</span>
								<span className="font-semibold text-gray-900">{statistics.assessments_taken}</span>
							</div>
							<div className="flex justify-between items-center py-2">
								<span className="text-sm text-gray-600">Latest Activity</span>
								<span className="text-sm text-gray-900">
									{formatDateShort(statistics.latest_activity)}
								</span>
							</div>
						</div>
					</div>
				</div>

				{/* Business Readiness Classifications */}
				{statistics.average_score !== null && (
					<div className="mb-8">
						<h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
							<Shield className="w-5 h-5 mr-2 text-purple-600" />
							Business Readiness Assessment
						</h3>
						<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
							{/* Export/Import Readiness Tier */}
							{exportReadiness && (
								<div className={`rounded-lg border p-6 ${exportReadiness.color}`}>
									<div className="flex items-center mb-4">
										<exportReadiness.icon className={`w-6 h-6 mr-3 ${exportReadiness.iconColor}`} />
										<div>
											<h4 className="text-lg font-semibold">{exportReadiness.tier}</h4>
											<p className="text-sm opacity-75">{exportReadiness.description}</p>
										</div>
									</div>
									<div className="space-y-2 mb-4">
										{exportReadiness.details.map((detail, index) => (
											<div key={index} className="flex items-start text-sm">
												<div className={`w-1.5 h-1.5 rounded-full mt-2 mr-2 flex-shrink-0 ${exportReadiness.iconColor.replace('text-', 'bg-')}`} />
												<span>{detail}</span>
											</div>
										))}
									</div>
									<div className={`text-sm font-medium p-3 rounded-md bg-white/50 border border-current/20`}>
										<strong>Remarks:</strong> {exportReadiness.remarks}
									</div>
								</div>
							)}

							{/* Business Classification Tier */}
							{businessClassification && (
								<div className={`rounded-lg border p-6 ${businessClassification.color}`}>
									<div className="flex items-center mb-4">
										<businessClassification.icon className={`w-6 h-6 mr-3 ${businessClassification.iconColor}`} />
										<div>
											<h4 className="text-lg font-semibold">{businessClassification.class} Business</h4>
											<p className="text-sm opacity-75">{businessClassification.description}</p>
										</div>
									</div>
									<div className="mb-4">
										<div className="text-sm flex justify-between items-center">
											<span>Current Score:</span>
											<span className="font-semibold">{statistics.average_score}%</span>
										</div>
										<div className="text-xs opacity-75 mt-1">
											Products threshold: {businessClassification.class === 'Class A' ? '>60' : businessClassification.class === 'Class B' ? '45-60' : '<45'} | 
											Services threshold: {businessClassification.class === 'Class A' ? '>49' : businessClassification.class === 'Class B' ? '34-49' : '<34'}
										</div>
									</div>
									<div className={`text-sm font-medium p-3 rounded-md bg-white/50 border border-current/20`}>
										<strong>Remarks:</strong> {businessClassification.remarks}
									</div>
								</div>
							)}
						</div>
					</div>
				)}

				{/* Assessment Response Analysis */}
				<div className="bg-white rounded-lg border border-gray-200 p-6">
					<h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
						<TrendingUp className="w-5 h-5 mr-2 text-blue-600" />
						Survey Response Analysis & History
					</h3>

					{assessments.length === 0 ? (
						<div className="text-center py-12">
							<FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
							<h4 className="text-lg font-medium text-gray-900 mb-2">No Assessment History</h4>
							<p className="text-gray-500">This business hasn't started any assessments yet.</p>
						</div>
					) : (
						<div className="overflow-x-auto">
							<Table hoverable>
								<TableHead>
									<TableHeadCell>Assessment</TableHeadCell>
									<TableHeadCell>Status</TableHeadCell>
									<TableHeadCell>Score & Grade</TableHeadCell>
									<TableHeadCell>Started</TableHeadCell>
									<TableHeadCell>Completed</TableHeadCell>
								</TableHead>
								<TableBody>
									{assessments.map((session) => {
										const stateConfig = getStateDisplay(session.state);
										const StateIcon = stateConfig.icon;
										const GradeIcon = getGradeIcon(session.grade);
										const scorePercentage = session.total_score && session.max_possible_score ? 
											Math.round((session.total_score / session.max_possible_score) * 100) : null;
										
										return (
											<TableRow key={session.id} className="bg-white hover:bg-gray-50 transition-colors">
												<TableCell className="font-medium">
													<div>
														<div className="font-semibold text-gray-900">
															{session.assessment.title}
														</div>
														<div className="text-sm text-gray-500 mt-1">
															{session.assessment.description}
														</div>
														<div className="text-xs text-gray-400 mt-1">
															Assessment ID: {session.assessment.id}
														</div>
													</div>
												</TableCell>
												<TableCell>
													<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium whitespace-nowrap ${
														stateConfig.color === 'success'
															? 'bg-green-100 text-green-800'
															: stateConfig.color === 'warning'
															? 'bg-red-100 text-red-800'
															: stateConfig.color === 'info'
															? 'bg-blue-100 text-blue-800'
															: 'bg-green-100 text-green-800'
													}`}>
														{stateConfig.label}
													</span>
												</TableCell>
												<TableCell>
													{scorePercentage !== null ? (
														<div className="flex items-center space-x-2">
															<div className="text-sm">
																<div className={`font-semibold ${getScoreColor(scorePercentage)}`}>
																	{scorePercentage}%
																</div>
																<div className="text-gray-500">
																	{session.total_score}/{session.max_possible_score}
																</div>
															</div>
															{session.grade && (
																<div className="flex items-center">
																	<GradeIcon className="w-4 h-4 text-yellow-500 mr-1" />
																	<span className="font-medium text-gray-700">
																		{session.grade}
																	</span>
																</div>
															)}
														</div>
													) : (
														<span className="text-gray-400">Not scored</span>
													)}
												</TableCell>
												<TableCell>
													{session.started_at ? (
														<span className="text-sm text-gray-900">
															{formatDate(session.started_at)}
														</span>
													) : (
														<span className="text-gray-400">Not started</span>
													)}
												</TableCell>
												<TableCell>
													{session.completed_at ? (
														<div className="text-sm">
															<span className="text-gray-900">
																{formatDate(session.completed_at)}
															</span>
															{session.started_at && (
																<div className="text-xs text-gray-500">
																	Duration: {Math.round(
																		(new Date(session.completed_at).getTime() - 
																		 new Date(session.started_at).getTime()) / (1000 * 60)
																	)} min
																</div>
															)}
														</div>
													) : (
														<span className="text-gray-400">In progress</span>
													)}
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
		</RouteGuard>
	);
};

export default BusinessDetail;

export const routePath = {
	path: "/app/businesses/:id",
	Component: BusinessDetail,
} as RouteObject;