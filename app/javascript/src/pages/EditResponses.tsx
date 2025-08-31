"use client";

import React, { useState, useEffect } from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import { Card, Badge } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import RouteGuard from "../components/RouteGuard";
import {
	FileText,
	ArrowLeft,
	Save,
	CheckCircle,
	AlertCircle,
	Clock,
	User,
	Edit,
	Calendar,
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";

// Reuse interfaces from TakeAssessment
interface AssessmentQuestion {
	id: number;
	text: string;
	type: string;
	question_type: string;
	question_type_name: string;
	order: number;
	is_required: boolean;
	active: boolean;
	meta_data: Record<string, any>;
	options: AssessmentQuestionOption[];
}

interface AssessmentQuestionOption {
	id: number;
	text: string;
	order: number;
	active: boolean;
}

interface AssessmentSection {
	id: number;
	name: string;
	order: number;
	questions_count: number;
	questions: AssessmentQuestion[];
}

interface Assessment {
	id: number;
	title: string;
	description: string;
	sections_count: number;
	questions_count: number;
	sections: AssessmentSection[];
}

interface AssessmentResponseSession {
	id: number;
	state: 'draft' | 'in_progress' | 'completed' | 'submitted';
	progress_percentage: number;
	started_at?: string;
	completed_at?: string;
	submitted_at?: string;
	total_score?: number;
	max_possible_score?: number;
	grade?: string;
	assessment: Assessment;
}

interface QuestionResponse {
	question_id: number;
	selected_option_ids?: number[];
	number?: number;
	text?: string;
	date?: string;
	boolean?: boolean;
}

// Mock data for completed assessment responses
const getCompletedResponseSession = (assessmentId: string, responseId: string): AssessmentResponseSession => {
	// For demo purposes, using the same assessment structure but with completed state
	const assessment: Assessment = {
		id: parseInt(assessmentId),
		title: "Global Technology Survey",
		description: "A comprehensive survey about technology usage and preferences across different regions.",
		sections_count: 3,
		questions_count: 12,
		sections: [
			{
				id: 1,
				name: "Technology Infrastructure",
				order: 1,
				questions_count: 4,
				questions: [
					{
						id: 1,
						text: "What is your primary technology platform?",
						type: "AssessmentQuestions::MultipleChoice",
						question_type: "multiple_choice",
						question_type_name: "Multiple Choice",
						order: 1,
						is_required: true,
						active: true,
						meta_data: {},
						options: [
							{ id: 1, text: "Cloud-based solutions", order: 1, active: true },
							{ id: 2, text: "On-premise infrastructure", order: 2, active: true },
							{ id: 3, text: "Hybrid approach", order: 3, active: true },
							{ id: 4, text: "Mobile-first solutions", order: 4, active: true }
						]
					},
					{
						id: 2,
						text: "How would you rate your organization's digital maturity?",
						type: "AssessmentQuestions::Radio",
						question_type: "radio",
						question_type_name: "Single Choice",
						order: 2,
						is_required: true,
						active: true,
						meta_data: {},
						options: [
							{ id: 5, text: "Beginner (1-2)", order: 1, active: true },
							{ id: 6, text: "Intermediate (3-4)", order: 2, active: true },
							{ id: 7, text: "Advanced (5)", order: 3, active: true }
						]
					},
					{
						id: 3,
						text: "Do you have a dedicated IT team?",
						type: "AssessmentQuestions::BooleanType",
						question_type: "boolean",
						question_type_name: "Yes/No",
						order: 3,
						is_required: true,
						active: true,
						meta_data: {},
						options: []
					},
					{
						id: 4,
						text: "What is your annual technology budget? (USD)",
						type: "AssessmentQuestions::RangeType",
						question_type: "range",
						question_type_name: "Number Range",
						order: 4,
						is_required: false,
						active: true,
						meta_data: { min: 0, max: 1000000 },
						options: []
					}
				]
			},
			{
				id: 2,
				name: "Digital Transformation",
				order: 2,
				questions_count: 4,
				questions: [
					{
						id: 5,
						text: "Which digital transformation initiatives are you currently pursuing?",
						type: "AssessmentQuestions::MultipleChoice",
						question_type: "multiple_choice",
						question_type_name: "Multiple Choice",
						order: 1,
						is_required: true,
						active: true,
						meta_data: {},
						options: [
							{ id: 8, text: "Process automation", order: 1, active: true },
							{ id: 9, text: "Data analytics", order: 2, active: true },
							{ id: 10, text: "Customer experience enhancement", order: 3, active: true },
							{ id: 11, text: "Digital marketing", order: 4, active: true },
							{ id: 12, text: "Remote work capabilities", order: 5, active: true }
						]
					},
					{
						id: 6,
						text: "When did you start your digital transformation journey?",
						type: "AssessmentQuestions::DateType",
						question_type: "date",
						question_type_name: "Date",
						order: 2,
						is_required: true,
						active: true,
						meta_data: {},
						options: []
					},
					{
						id: 7,
						text: "Is digital transformation a strategic priority for your organization?",
						type: "AssessmentQuestions::BooleanType",
						question_type: "boolean",
						question_type_name: "Yes/No",
						order: 3,
						is_required: true,
						active: true,
						meta_data: {},
						options: []
					},
					{
						id: 8,
						text: "Please describe your biggest digital transformation challenge.",
						type: "AssessmentQuestions::RichText",
						question_type: "rich_text",
						question_type_name: "Text Area",
						order: 4,
						is_required: false,
						active: true,
						meta_data: {},
						options: []
					}
				]
			},
			{
				id: 3,
				name: "Future Planning",
				order: 3,
				questions_count: 4,
				questions: [
					{
						id: 9,
						text: "What are your technology priorities for the next 2 years?",
						type: "AssessmentQuestions::MultipleChoice",
						question_type: "multiple_choice",
						question_type_name: "Multiple Choice",
						order: 1,
						is_required: true,
						active: true,
						meta_data: {},
						options: [
							{ id: 13, text: "Artificial Intelligence integration", order: 1, active: true },
							{ id: 14, text: "Cybersecurity enhancement", order: 2, active: true },
							{ id: 15, text: "Cloud migration", order: 3, active: true },
							{ id: 16, text: "Data governance", order: 4, active: true },
							{ id: 17, text: "Mobile optimization", order: 5, active: true }
						]
					},
					{
						id: 10,
						text: "Rate your confidence in achieving your technology goals (1-10)",
						type: "AssessmentQuestions::RangeType",
						question_type: "range",
						question_type_name: "Number Range",
						order: 2,
						is_required: true,
						active: true,
						meta_data: { min: 1, max: 10 },
						options: []
					},
					{
						id: 11,
						text: "Do you plan to increase technology spending next year?",
						type: "AssessmentQuestions::BooleanType",
						question_type: "boolean",
						question_type_name: "Yes/No",
						order: 3,
						is_required: true,
						active: true,
						meta_data: {},
						options: []
					},
					{
						id: 12,
						text: "Any additional comments about your technology strategy?",
						type: "AssessmentQuestions::RichText",
						question_type: "rich_text",
						question_type_name: "Text Area",
						order: 4,
						is_required: false,
						active: true,
						meta_data: {},
						options: []
					}
				]
			}
		]
	};

	return {
		id: parseInt(responseId),
		state: 'completed',
		progress_percentage: 100,
		started_at: "2024-11-15T10:30:00.000Z",
		completed_at: "2024-11-15T11:45:00.000Z",
		submitted_at: "2024-11-15T11:45:00.000Z",
		assessment
	};
};

// Mock existing responses - simulating what the user previously answered
const getExistingResponses = (responseId: string): Record<number, QuestionResponse> => {
	return {
		1: { question_id: 1, selected_option_ids: [1, 3] }, // Cloud + Hybrid
		2: { question_id: 2, selected_option_ids: [6] }, // Intermediate
		3: { question_id: 3, boolean: true }, // Has IT team
		4: { question_id: 4, number: 50000 }, // Budget
		5: { question_id: 5, selected_option_ids: [8, 9, 10] }, // Process automation, data analytics, CX
		6: { question_id: 6, date: "2023-01-15" }, // Transformation start date
		7: { question_id: 7, boolean: true }, // Strategic priority
		8: { question_id: 8, text: "Integration challenges with legacy systems and resistance to change from traditional departments." }, // Challenge description
		9: { question_id: 9, selected_option_ids: [13, 14, 15] }, // AI, Cybersecurity, Cloud
		10: { question_id: 10, number: 7 }, // Confidence rating
		11: { question_id: 11, boolean: true }, // Increase spending
		12: { question_id: 12, text: "Focus on building a more resilient and scalable technology foundation for future growth." } // Additional comments
	};
};

const EditResponses: React.FC = () => {
	const { assessmentId, responseId } = useParams<{ assessmentId: string; responseId: string }>();
	const navigate = useNavigate();
	const { user } = useAuth();
	const [responseSession, setResponseSession] = useState<AssessmentResponseSession | null>(null);
	const [responses, setResponses] = useState<Record<number, QuestionResponse>>({});
	const [loading, setLoading] = useState(true);
	const [saving, setSaving] = useState(false);
	const [expandedSections, setExpandedSections] = useState<Record<number, boolean>>({});

	useEffect(() => {
		if (assessmentId && responseId) {
			// Load the completed assessment response session
			const session = getCompletedResponseSession(assessmentId, responseId);
			setResponseSession(session);
			
			// Load existing responses
			const existingResponses = getExistingResponses(responseId);
			setResponses(existingResponses);
			
			// Expand all sections by default
			const expanded: Record<number, boolean> = {};
			session.assessment.sections.forEach(section => {
				expanded[section.id] = true;
			});
			setExpandedSections(expanded);
			
			setLoading(false);
		}
	}, [assessmentId, responseId]);

	const handleResponseChange = (questionId: number, response: Partial<QuestionResponse>) => {
		setResponses(prev => ({
			...prev,
			[questionId]: { ...prev[questionId], question_id: questionId, ...response }
		}));
	};

	const handleSaveChanges = async () => {
		setSaving(true);
		// Simulate API call to save changes
		setTimeout(() => {
			setSaving(false);
			// Navigate back to assessments with success message
			navigate('/app/my-assessments', { 
				state: { message: 'Response changes saved successfully!' }
			});
		}, 1500);
	};

	const toggleSection = (sectionId: number) => {
		setExpandedSections(prev => ({
			...prev,
			[sectionId]: !prev[sectionId]
		}));
	};

	const formatDate = (dateString: string | undefined) => {
		if (!dateString) return "Not completed";
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "long",
			day: "numeric",
			hour: "2-digit",
			minute: "2-digit",
		});
	};

	const renderQuestion = (question: AssessmentQuestion) => {
		const response = responses[question.id];

		switch (question.question_type) {
			case 'multiple_choice':
				return (
					<div className="space-y-3">
						{question.options.map((option) => (
							<label key={option.id} className="flex items-center space-x-3 p-3 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer">
								<input
									type="checkbox"
									checked={response?.selected_option_ids?.includes(option.id) || false}
									onChange={(e) => {
										const currentIds = response?.selected_option_ids || [];
										const newIds = e.target.checked 
											? [...currentIds, option.id]
											: currentIds.filter(id => id !== option.id);
										handleResponseChange(question.id, { selected_option_ids: newIds });
									}}
									className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500"
								/>
								<span className="text-sm font-medium text-gray-900">{option.text}</span>
							</label>
						))}
					</div>
				);

			case 'radio':
				return (
					<div className="space-y-3">
						{question.options.map((option) => (
							<label key={option.id} className="flex items-center space-x-3 p-3 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer">
								<input
									type="radio"
									name={`question-${question.id}`}
									checked={response?.selected_option_ids?.[0] === option.id || false}
									onChange={() => {
										handleResponseChange(question.id, { selected_option_ids: [option.id] });
									}}
									className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
								/>
								<span className="text-sm font-medium text-gray-900">{option.text}</span>
							</label>
						))}
					</div>
				);

			case 'boolean':
				return (
					<div className="flex space-x-4">
						<label className="flex items-center space-x-2 cursor-pointer">
							<input
								type="radio"
								name={`question-${question.id}`}
								checked={response?.boolean === true}
								onChange={() => handleResponseChange(question.id, { boolean: true })}
								className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
							/>
							<span className="text-sm font-medium text-gray-900">Yes</span>
						</label>
						<label className="flex items-center space-x-2 cursor-pointer">
							<input
								type="radio"
								name={`question-${question.id}`}
								checked={response?.boolean === false}
								onChange={() => handleResponseChange(question.id, { boolean: false })}
								className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
							/>
							<span className="text-sm font-medium text-gray-900">No</span>
						</label>
					</div>
				);

			case 'range':
				const min = question.meta_data?.min || 0;
				const max = question.meta_data?.max || 100;
				return (
					<div className="space-y-4">
						<input
							type="number"
							min={min}
							max={max}
							value={response?.number || ''}
							onChange={(e) => handleResponseChange(question.id, { number: parseInt(e.target.value) || 0 })}
							placeholder={`Enter a number between ${min} and ${max}`}
							className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
						/>
						<div className="text-xs text-gray-500">
							Range: {min} - {max}
						</div>
					</div>
				);

			case 'date':
				return (
					<input
						type="date"
						value={response?.date || ''}
						onChange={(e) => handleResponseChange(question.id, { date: e.target.value })}
						className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
					/>
				);

			case 'rich_text':
				return (
					<textarea
						rows={4}
						value={response?.text || ''}
						onChange={(e) => handleResponseChange(question.id, { text: e.target.value })}
						placeholder="Enter your response..."
						className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
					/>
				);

			default:
				return (
					<div className="text-gray-500 italic">
						Question type "{question.question_type}" not yet implemented.
					</div>
				);
		}
	};

	if (loading) {
		return (
			<RouteGuard requireAdmin={false}>
				<DashboardLayout>
					<DashboardLayout.Sidebar>
						<ApplicationSidebar />
					</DashboardLayout.Sidebar>
					<DashboardLayout.Content>
						<div className="flex items-center justify-center h-96">
							<div className="text-center">
								<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto mb-4"></div>
								<p className="text-gray-500">Loading assessment responses...</p>
							</div>
						</div>
					</DashboardLayout.Content>
				</DashboardLayout>
			</RouteGuard>
		);
	}

	if (!responseSession) {
		return (
			<RouteGuard requireAdmin={false}>
				<DashboardLayout>
					<DashboardLayout.Sidebar>
						<ApplicationSidebar />
					</DashboardLayout.Sidebar>
					<DashboardLayout.Content>
						<div className="text-center py-12">
							<AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
							<h3 className="text-lg font-medium text-gray-900 mb-2">Response Session Not Found</h3>
							<p className="text-gray-500 mb-4">The requested response session could not be loaded.</p>
							<button
								onClick={() => navigate('/app/my-assessments')}
								className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors mx-auto"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back to Assessments
							</button>
						</div>
					</DashboardLayout.Content>
				</DashboardLayout>
			</RouteGuard>
		);
	}

	return (
		<RouteGuard requireAdmin={false}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

				<DashboardLayout.Content>
					{/* Header */}
					<div className="flex items-center justify-between mb-8">
						<div className="flex items-center space-x-4">
							<button
								onClick={() => navigate('/app/my-assessments')}
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
							<div>
								<h1 className="text-2xl font-bold text-gray-900">Edit Assessment Responses</h1>
								<p className="text-gray-600 mt-1">{responseSession.assessment.title}</p>
							</div>
						</div>
						<div className="flex items-center space-x-3">
							<Badge color="success" className="whitespace-nowrap">
								<CheckCircle className="w-3 h-3 mr-1" />
								Completed
							</Badge>
						</div>
					</div>

					{/* Assessment Info */}
					<Card className="mb-8 border border-gray-200 shadow-none">
						<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
							<div className="flex items-center space-x-3">
								<div className="p-3 rounded-full bg-green-100">
									<CheckCircle className="w-6 h-6 text-green-600" />
								</div>
								<div>
									<p className="text-sm font-medium text-gray-600">Status</p>
									<p className="text-lg font-medium text-gray-900">Completed</p>
								</div>
							</div>
							<div className="flex items-center space-x-3">
								<div className="p-3 rounded-full bg-blue-100">
									<Calendar className="w-6 h-6 text-blue-600" />
								</div>
								<div>
									<p className="text-sm font-medium text-gray-600">Completed On</p>
									<p className="text-lg font-medium text-gray-900">{formatDate(responseSession.completed_at)}</p>
								</div>
							</div>
							<div className="flex items-center space-x-3">
								<div className="p-3 rounded-full bg-purple-100">
									<User className="w-6 h-6 text-purple-600" />
								</div>
								<div>
									<p className="text-sm font-medium text-gray-600">Respondent</p>
									<p className="text-lg font-medium text-gray-900">{user?.display_name || user?.full_name || 'User'}</p>
								</div>
							</div>
						</div>
					</Card>

					{/* Responses by Section */}
					<div className="space-y-6">
						{responseSession.assessment.sections.map((section) => (
							<Card key={section.id} className="border border-gray-200 shadow-none">
								<div 
									className="flex items-center justify-between cursor-pointer"
									onClick={() => toggleSection(section.id)}
								>
									<div className="flex items-center space-x-3">
										<div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
											<FileText className="w-4 h-4 text-purple-600" />
										</div>
										<div>
											<h3 className="text-lg font-semibold text-gray-900">{section.name}</h3>
											<p className="text-sm text-gray-500">{section.questions_count} questions</p>
										</div>
									</div>
									<div className="flex items-center space-x-2">
										<Badge color="success" className="whitespace-nowrap">
											<CheckCircle className="w-3 h-3 mr-1" />
											Complete
										</Badge>
										<div className={`w-5 h-5 transition-transform ${expandedSections[section.id] ? 'rotate-180' : ''}`}>
											<svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
											</svg>
										</div>
									</div>
								</div>

								{expandedSections[section.id] && (
									<div className="mt-6 space-y-8 border-t border-gray-200 pt-6">
										{section.questions.map((question) => (
											<div key={question.id} className="space-y-4">
												<div className="flex items-start justify-between">
													<div className="flex-1">
														<h4 className="text-base font-medium text-gray-900 mb-2">
															{question.text}
														</h4>
														<div className="flex items-center space-x-4 text-xs text-gray-500 mb-4">
															<span>{question.question_type_name}</span>
															{question.is_required && (
																<span className="flex items-center text-red-600">
																	<AlertCircle className="w-3 h-3 mr-1" />
																	Required
																</span>
															)}
														</div>
													</div>
													<Edit className="w-4 h-4 text-purple-600 mt-1 flex-shrink-0" />
												</div>
												{renderQuestion(question)}
											</div>
										))}
									</div>
								)}
							</Card>
						))}
					</div>

					{/* Save Button */}
					<div className="flex justify-end mt-8 pt-6 border-t border-gray-200">
						<button
							onClick={handleSaveChanges}
							disabled={saving}
							className="flex items-center px-6 py-3 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50"
						>
							{saving ? (
								<>
									<div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
									Saving Changes...
								</>
							) : (
								<>
									<Save className="w-4 h-4 mr-2" />
									Save Changes
								</>
							)}
						</button>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		</RouteGuard>
	);
};

export default EditResponses;

export const routePath = {
	path: "/app/assessments/:assessmentId/responses/:responseId/edit",
	Component: EditResponses,
} as RouteObject;