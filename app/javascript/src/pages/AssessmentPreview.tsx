"use client";

import { useState, useEffect } from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import { Card, Alert, Button } from "flowbite-react";
import {
	ArrowLeft,
	FileText,
	CheckSquare,
	Circle,
	Calendar,
	Clock,
	User,
	Upload,
	AlertCircle,
	Eye,
	Play,
	Info,
	Share2,
	Plus,
	Check,
	Copy,
} from "lucide-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { fetchAssessment, fetchAssessmentSections } from "../api/assessments";
import {
	getVisibleSections,
	QuestionResponse,
	createTestResponse,
	type Question as ConditionalQuestion,
	type Section as ConditionalSection,
} from "../utils/conditionalLogic";
import { generateSurveyUrl } from "../utils/surveyLink";

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

interface QuestionOption {
	id: number;
	text: string;
	order: number;
}

interface Question {
	id: number;
	text: string;
	type: string;
	question_type_name: string;
	sub_type: string;
	order: number;
	is_required: boolean;
	active: boolean;
	is_conditional?: boolean;
	options: QuestionOption[];
	meta_data?: any;
}

interface Section {
	id: number;
	name: string;
	order: number;
	is_conditional?: boolean;
	has_country_restrictions?: boolean;
	restricted_countries?: string[];
	questions_count?: number;
	questions: Question[];
	created_at?: string;
	updated_at?: string;
}

export default function AssessmentPreview() {
	const { id } = useParams();
	const navigate = useNavigate();

	const [assessment, setAssessment] = useState<Assessment | null>(null);
	const [allSections, setAllSections] = useState<Section[]>([]);
	const [visibleSections, setVisibleSections] = useState<Section[]>([]);
	const [responses, setResponses] = useState<Map<number, QuestionResponse>>(new Map());
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [showConditionalInfo, setShowConditionalInfo] = useState(false);
	const [showCopySuccess, setShowCopySuccess] = useState(false);

	useEffect(() => {
		const loadAssessmentData = async () => {
			if (!id) return;

			try {
				const [assessmentResponse, sectionsData] = await Promise.all([
					fetchAssessment(Number(id)),
					fetchAssessmentSections(Number(id)),
				]);

				// Handle nested assessment structure
				const assessmentData = assessmentResponse?.assessment || assessmentResponse;

				setAssessment(assessmentData);
				setAllSections(sectionsData || []);
				// Initialize with all sections visible (no responses yet)
				setVisibleSections(sectionsData || []);
			} catch (err) {
				console.error("Failed to fetch assessment data:", err);
				setError(err instanceof Error ? err.message : "Failed to load assessment");
			} finally {
				setLoading(false);
			}
		};

		loadAssessmentData();
	}, [id]);

	// Handle response changes and update visibility
	const handleResponseChange = (
		questionId: number,
		value: any,
		type: "option" | "text" | "number" | "boolean"
	) => {
		const newResponse = createTestResponse(questionId, type, value);
		const newResponses = new Map(responses);
		newResponses.set(questionId, newResponse);
		setResponses(newResponses);

		// Update visible sections based on new responses
		const newVisibleSections = getVisibleSections(
			allSections as ConditionalSection[],
			newResponses
		);
		setVisibleSections(newVisibleSections as Section[]);
	};

	// Count conditional questions
	const getConditionalStats = () => {
		const totalQuestions = allSections.reduce(
			(sum, section) => sum + section.questions.length,
			0
		);
		const visibleQuestions = visibleSections.reduce(
			(sum, section) => sum + section.questions.length,
			0
		);
		const conditionalQuestions = allSections.reduce(
			(sum, section) => sum + section.questions.filter((q) => q.is_conditional).length,
			0
		);
		const conditionalSections = allSections.filter((s) => s.is_conditional).length;

		return {
			totalQuestions,
			visibleQuestions,
			hiddenQuestions: totalQuestions - visibleQuestions,
			conditionalQuestions,
			conditionalSections,
		};
	};

	// Handle sharing survey link
	const handleShareSurvey = async () => {
		if (!id || !assessment) return;

		const surveyUrl = generateSurveyUrl(Number(id));

		try {
			if (navigator.clipboard && window.isSecureContext) {
				await navigator.clipboard.writeText(surveyUrl);
				setShowCopySuccess(true);
				setTimeout(() => setShowCopySuccess(false), 2000);
			} else {
				// Fallback for non-secure contexts
				const textArea = document.createElement("textarea");
				textArea.value = surveyUrl;
				document.body.appendChild(textArea);
				textArea.select();
				document.execCommand("copy");
				document.body.removeChild(textArea);
				setShowCopySuccess(true);
				setTimeout(() => setShowCopySuccess(false), 2000);
			}
		} catch (err) {
			console.error("Failed to copy survey link:", err);
			// Fallback: open in new tab
			window.open(surveyUrl, "_blank");
		}
	};

	const getQuestionTypeIcon = (questionType: string, subType: string) => {
		switch (questionType) {
			case "AssessmentQuestions::MultipleChoice":
				return <CheckSquare className="w-5 h-5 text-green-600" />;
			case "AssessmentQuestions::Radio":
				return <Circle className="w-5 h-5 text-purple-600" />;
			case "AssessmentQuestions::DateType":
				return <Calendar className="w-5 h-5 text-blue-600" />;
			case "AssessmentQuestions::RangeType":
				return <Clock className="w-5 h-5 text-orange-600" />;
			case "AssessmentQuestions::FileUpload":
				return <Upload className="w-5 h-5 text-gray-600" />;
			case "AssessmentQuestions::RichText":
				return <FileText className="w-5 h-5 text-gray-600" />;
			case "AssessmentQuestions::BooleanType":
				return <CheckSquare className="w-5 h-5 text-indigo-600" />;
			default:
				return <FileText className="w-5 h-5 text-gray-600" />;
		}
	};

	const renderQuestionPreview = (question: Question) => {
		const isRequired = question.is_required;

		return (
			<div
				key={question.id}
				className="border border-gray-200 rounded-lg p-6 bg-white shadow-none"
			>
				<div className="flex items-start space-x-4">
					<div className="flex-shrink-0">
						{getQuestionTypeIcon(question.type, question.sub_type)}
					</div>
					<div className="flex-1 min-w-0">
						<div className="flex items-start justify-between mb-2">
							<h4 className="text-base font-medium text-gray-900 pr-2">{question.text}</h4>
							{isRequired && (
								<span className="text-red-500 text-base font-medium flex-shrink-0">*</span>
							)}
						</div>

						<div className="text-sm text-gray-500 mb-4">
							{question.question_type_name}
							{question.sub_type && ` (${question.sub_type})`}
						</div>

						{/* Render options for choice-based questions */}
						{(question.type.includes("MultipleChoice") || question.type.includes("Radio")) &&
							question.options &&
							question.options.length > 0 && (
								<div className="space-y-3">
									{question.options.map((option, index) => (
										<div
											key={option.id || index}
											className="flex items-center space-x-3 p-2 rounded-md hover:bg-gray-50 transition-colors"
										>
											{question.type.includes("MultipleChoice") ? (
												<input
													type="checkbox"
													className="rounded border-gray-300 text-purple-600 focus:ring-purple-500 focus:ring-2"
												/>
											) : (
												<input
													type="radio"
													name={`question-${question.id}`}
													className="border-gray-300 text-purple-600 focus:ring-purple-500 focus:ring-2"
												/>
											)}
											<span className="text-gray-700 text-sm">{option.text}</span>
										</div>
									))}
								</div>
							)}

						{/* Render input field for text-based questions */}
						{question.type.includes("RichText") && (
							<div className="mt-3">
								{question.sub_type === "long_text" ? (
									<textarea
										rows={3}
										className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500"
										placeholder="Type your answer here..."
									/>
								) : (
									<input
										type="text"
										className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500"
										placeholder="Type your answer here..."
									/>
								)}
							</div>
						)}

						{/* Render date input for date questions */}
						{question.type.includes("DateType") && (
							<div className="mt-3">
								<input
									type="date"
									className="px-3 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500"
								/>
							</div>
						)}

						{/* Render range input for range questions */}
						{question.type.includes("RangeType") && (
							<div className="mt-3">
								<input
									type="range"
									className="w-full accent-purple-600"
									min="1"
									max="10"
									defaultValue="5"
								/>
								<div className="flex justify-between text-xs text-gray-500 mt-1">
									<span>1</span>
									<span>10</span>
								</div>
							</div>
						)}

						{/* Render file upload for file questions */}
						{question.type.includes("FileUpload") && (
							<div className="mt-3">
								<div className="border-2 border-dashed border-purple-300 rounded-lg p-4 text-center bg-purple-50 hover:bg-purple-100 transition-colors cursor-pointer">
									<Upload className="w-8 h-8 text-purple-500 mx-auto mb-2" />
									<p className="text-sm text-purple-700">
										Click to upload or drag and drop
									</p>
									<p className="text-xs text-purple-600 mt-1">
										Files won't actually be uploaded in preview mode
									</p>
									<input type="file" className="hidden" />
								</div>
							</div>
						)}

						{/* Render yes/no for boolean questions */}
						{question.type.includes("BooleanType") && (
							<div className="space-y-3">
								<div className="flex items-center space-x-3 p-2 rounded-md hover:bg-gray-50 transition-colors">
									<input
										type="radio"
										name={`question-${question.id}`}
										className="border-gray-300 text-purple-600 focus:ring-purple-500 focus:ring-2"
									/>
									<span className="text-gray-700 text-sm">Yes</span>
								</div>
								<div className="flex items-center space-x-3 p-2 rounded-md hover:bg-gray-50 transition-colors">
									<input
										type="radio"
										name={`question-${question.id}`}
										className="border-gray-300 text-purple-600 focus:ring-purple-500 focus:ring-2"
									/>
									<span className="text-gray-700 text-sm">No</span>
								</div>
							</div>
						)}
					</div>
				</div>
			</div>
		);
	};

	if (loading) {
		return (
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>
				<DashboardLayout.Content>
					<div className="flex items-center justify-center h-64">
						<div className="flex items-center space-x-3">
							<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
							<span className="text-lg text-gray-600">Loading assessment preview...</span>
						</div>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		);
	}

	if (error || !assessment) {
		return (
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>
				<DashboardLayout.Content>
					<div className="max-w-4xl mx-auto">
						<Alert color="failure" icon={AlertCircle}>
							<span className="font-medium">Error!</span> {error || "Assessment not found"}
						</Alert>
						<div className="mt-6">
							<button
								onClick={() => navigate(-1)}
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
						</div>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		);
	}

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				<div className="max-w-4xl mx-auto space-y-6">
					{/* Header */}
					<div className="flex items-center justify-between">
						<div className="flex items-center">
							<button
								onClick={() => navigate(-1)}
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors mr-4"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
							<div className="ml-2">
								<h1 className="text-2xl font-semibold text-gray-900">Assessment Preview</h1>
								<p className="text-gray-600 mt-1">
									Review how this assessment will appear to respondents
								</p>
							</div>
						</div>
						<button
							onClick={handleShareSurvey}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors relative"
							title="Copy survey link to clipboard"
						>
							{showCopySuccess ? (
								<>
									<Check className="w-4 h-4 mr-2 text-green-600" />
									Copied!
								</>
							) : (
								<>
									<Copy className="w-4 h-4 mr-2" />
									Copy Survey Link
								</>
							)}
						</button>
					</div>

					{/* Assessment Overview Cards */}
					<div className="grid grid-cols-1 md:grid-cols-4 gap-6">
						<Card className="border border-gray-200 shadow-none">
							<div className="flex items-center">
								<div className="p-3 rounded-full bg-blue-100">
									<FileText className="w-6 h-6 text-blue-600" />
								</div>
								<div className="ml-4">
									<p className="text-sm font-medium text-gray-500">Sections</p>
									<p className="text-2xl font-semibold text-gray-900">
										{assessment.sections_count}
									</p>
								</div>
							</div>
						</Card>

						<Card className="border border-gray-200 shadow-none">
							<div className="flex items-center">
								<div className="p-3 rounded-full bg-green-100">
									<CheckSquare className="w-6 h-6 text-green-600" />
								</div>
								<div className="ml-4">
									<p className="text-sm font-medium text-gray-500">Questions</p>
									<p className="text-2xl font-semibold text-gray-900">
										{assessment.questions_count}
									</p>
								</div>
							</div>
						</Card>

						<Card className="border border-gray-200 shadow-none">
							<div className="flex items-center">
								<div className="p-3 rounded-full bg-purple-100">
									<Eye className="w-6 h-6 text-purple-600" />
								</div>
								<div className="ml-4">
									<p className="text-sm font-medium text-gray-500">Status</p>
									<p className="text-lg font-semibold text-gray-900">
										{assessment.active ? "Active" : "Draft"}
									</p>
								</div>
							</div>
						</Card>

						<Card className="border border-gray-200 shadow-none">
							<div className="flex items-center">
								<div className="p-3 rounded-full bg-orange-100">
									<Calendar className="w-6 h-6 text-orange-600" />
								</div>
								<div className="ml-4">
									<p className="text-sm font-medium text-gray-500">Created</p>
									<p className="text-sm font-semibold text-gray-900">
										{new Date(assessment.created_at).toLocaleDateString()}
									</p>
								</div>
							</div>
						</Card>
					</div>

					{/* Assessment Details */}
					<Card className="border border-gray-200 shadow-none">
						<div>
							<div className="flex items-center space-x-4 mb-4">
								<div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
									<FileText className="w-6 h-6 text-blue-600" />
								</div>
								<div>
									<h2 className="text-xl font-semibold text-gray-900">
										{assessment.title}
									</h2>
									{assessment.description && (
										<p className="text-gray-600 mt-1">{assessment.description}</p>
									)}
								</div>
							</div>
							{assessment.has_country_restrictions && (
								<div className="mt-4 p-3 bg-orange-50 border border-orange-200 rounded-lg">
									<p className="text-sm text-orange-800">
										<strong>Country Restrictions:</strong> This assessment has geographic
										limitations
									</p>
								</div>
							)}
						</div>
					</Card>

					{/* Sections */}
					{visibleSections.map((section, sectionIndex) => (
						<Card key={section.id} className="border border-gray-200 shadow-none">
							<div className="p-6">
								<div className="flex items-center space-x-3 mb-6">
									<div className="w-8 h-8 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center font-semibold text-sm">
										{sectionIndex + 1}
									</div>
									<h3 className="text-lg font-semibold text-gray-900">{section.name}</h3>
								</div>

								<div className="space-y-4">
									{section.questions && section.questions.length > 0 ? (
										section.questions
											.sort((a, b) => a.order - b.order)
											.map((question) => renderQuestionPreview(question))
									) : (
										<div className="text-center py-12 text-gray-500">
											<FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
											<h4 className="text-lg font-medium text-gray-900 mb-2">
												No questions yet
											</h4>
											<p className="text-gray-500 mb-4">
												This section doesn't have any questions. Questions will appear
												here once they are added to the assessment.
											</p>
											<button
												onClick={() => navigate(`/app/assessments/${id}/sections`)}
												className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
											>
												<Plus className="w-4 h-4 mr-2" />
												Add Questions
											</button>
										</div>
									)}
								</div>
							</div>
						</Card>
					))}

					{allSections.length === 0 && (
						<Card className="border border-gray-200 shadow-none">
							<div className="text-center py-12">
								<FileText className="w-16 h-16 text-gray-400 mx-auto mb-4" />
								<h3 className="text-lg font-medium text-gray-900 mb-2">
									No content available
								</h3>
								<p className="text-gray-500 mb-4">
									This assessment doesn't have any sections or questions yet.
								</p>
								<button
									onClick={() => navigate(`/app/assessments/${id}/sections`)}
									className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
								>
									<Plus className="w-4 h-4 mr-2" />
									Add Content
								</button>
							</div>
						</Card>
					)}

					{/* Footer */}
					{allSections.length > 0 && (
						<Card className="border border-gray-200 shadow-none">
							<div className="text-center py-6">
								<div className="flex items-center justify-center space-x-2 mb-2">
									<Info className="w-5 h-5 text-blue-600" />
									<p className="text-sm font-medium text-gray-900">Preview Mode</p>
								</div>
								<p className="text-sm text-gray-500">
									This is a preview of the assessment. Responses cannot be submitted in
									preview mode.
								</p>
							</div>
						</Card>
					)}
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments/:id/preview",
	Component: AssessmentPreview,
} as RouteObject;
