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
	Play
} from "lucide-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { fetchAssessment, fetchAssessmentSections } from "../api/assessments";

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
	options: QuestionOption[];
}

interface Section {
	id: number;
	name: string;
	order: number;
	questions: Question[];
}

export default function AssessmentPreview() {
	const { id } = useParams();
	const navigate = useNavigate();
	
	const [assessment, setAssessment] = useState<Assessment | null>(null);
	const [sections, setSections] = useState<Section[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		const loadAssessmentData = async () => {
			if (!id) return;
			
			try {
				const [assessmentData, sectionsData] = await Promise.all([
					fetchAssessment(Number(id)),
					fetchAssessmentSections(Number(id))
				]);
				
				setAssessment(assessmentData);
				setSections(sectionsData);
			} catch (err) {
				console.error('Failed to fetch assessment data:', err);
				setError(err instanceof Error ? err.message : 'Failed to load assessment');
			} finally {
				setLoading(false);
			}
		};

		loadAssessmentData();
	}, [id]);

	const getQuestionTypeIcon = (questionType: string, subType: string) => {
		switch (questionType) {
			case 'AssessmentQuestions::MultipleChoice':
				return <CheckSquare className="w-5 h-5 text-green-600" />;
			case 'AssessmentQuestions::Radio':
				return <Circle className="w-5 h-5 text-purple-600" />;
			case 'AssessmentQuestions::DateType':
				return <Calendar className="w-5 h-5 text-blue-600" />;
			case 'AssessmentQuestions::RangeType':
				return <Clock className="w-5 h-5 text-orange-600" />;
			case 'AssessmentQuestions::FileUpload':
				return <Upload className="w-5 h-5 text-gray-600" />;
			case 'AssessmentQuestions::RichText':
				return <FileText className="w-5 h-5 text-gray-600" />;
			case 'AssessmentQuestions::BooleanType':
				return <CheckSquare className="w-5 h-5 text-indigo-600" />;
			default:
				return <FileText className="w-5 h-5 text-gray-600" />;
		}
	};

	const renderQuestionPreview = (question: Question) => {
		const isRequired = question.is_required;

		return (
			<div key={question.id} className="border border-gray-200 rounded-lg p-6 bg-white">
				<div className="flex items-start space-x-3">
					{getQuestionTypeIcon(question.type, question.sub_type)}
					<div className="flex-1">
						<div className="flex items-start space-x-2 mb-3">
							<h3 className="text-lg font-medium text-gray-900 flex-1">
								{question.text}
							</h3>
							{isRequired && (
								<span className="text-red-500 text-lg font-medium flex-shrink-0 mt-0">*</span>
							)}
						</div>
						
						<div className="text-sm text-gray-500 mb-4">
							{question.question_type_name}
							{question.sub_type && ` (${question.sub_type})`}
						</div>

						{/* Render options for choice-based questions */}
						{(question.type.includes('MultipleChoice') || question.type.includes('Radio')) && question.options && question.options.length > 0 && (
							<div className="space-y-2">
								{question.options.map((option, index) => (
									<div key={option.id || index} className="flex items-center space-x-3">
										{question.type.includes('MultipleChoice') ? (
											<input 
												type="checkbox" 
												className="rounded border-gray-300 text-purple-600 focus:ring-purple-500"
											/>
										) : (
											<input 
												type="radio" 
												name={`question-${question.id}`}
												className="border-gray-300 text-purple-600 focus:ring-purple-500"
											/>
										)}
										<span className="text-gray-700">{option.text}</span>
									</div>
								))}
							</div>
						)}

						{/* Render input field for text-based questions */}
						{question.type.includes('RichText') && (
							<div className="mt-3">
								{question.sub_type === 'long_text' ? (
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
						{question.type.includes('DateType') && (
							<div className="mt-3">
								<input 
									type="date"
									className="px-3 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500"
								/>
							</div>
						)}

						{/* Render range input for range questions */}
						{question.type.includes('RangeType') && (
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
						{question.type.includes('FileUpload') && (
							<div className="mt-3">
								<div className="border-2 border-dashed border-purple-300 rounded-lg p-4 text-center bg-purple-50 hover:bg-purple-100 transition-colors cursor-pointer">
									<Upload className="w-8 h-8 text-purple-500 mx-auto mb-2" />
									<p className="text-sm text-purple-700">Click to upload or drag and drop</p>
									<p className="text-xs text-purple-600 mt-1">Files won't actually be uploaded in preview mode</p>
									<input type="file" className="hidden" />
								</div>
							</div>
						)}

						{/* Render yes/no for boolean questions */}
						{question.type.includes('BooleanType') && (
							<div className="mt-3 space-y-2">
								<div className="flex items-center space-x-3">
									<input 
										type="radio" 
										name={`question-${question.id}`}
										className="border-gray-300 text-purple-600 focus:ring-purple-500"
									/>
									<span className="text-gray-700">Yes</span>
								</div>
								<div className="flex items-center space-x-3">
									<input 
										type="radio" 
										name={`question-${question.id}`}
										className="border-gray-300 text-purple-600 focus:ring-purple-500"
									/>
									<span className="text-gray-700">No</span>
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
							<span className="font-medium">Error!</span> {error || 'Assessment not found'}
						</Alert>
						<div className="mt-6">
							<Button onClick={() => navigate('/app')} color="gray">
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back to Assessments
							</Button>
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
				<div className="max-w-4xl mx-auto">
					{/* Header */}
					<div className="mb-8">
						{/* Preview Mode Banner */}
						<div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-lg p-4 mb-6">
							<div className="flex items-center justify-between">
								<div className="flex items-center space-x-3">
									<div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
										<Eye className="w-5 h-5 text-white" />
									</div>
									<div>
										<h2 className="text-lg font-semibold text-blue-900">Assessment Preview</h2>
										<p className="text-sm text-blue-700">You can interact with this form, but responses won't be saved</p>
									</div>
								</div>
								<div className="flex items-center space-x-2">
									<span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
										<Play className="w-3 h-3 mr-1" />
										Try it out
									</span>
								</div>
							</div>
						</div>

						{/* Navigation */}
						<div className="flex items-center space-x-4">
							<Button
								onClick={() => navigate('/app')}
								color="gray"
								size="sm"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back to Assessments
							</Button>
						</div>
					</div>

					{/* Assessment Header */}
					<div className="mb-8">
						<Card className="bg-gradient-to-br from-white to-gray-50 border-0 shadow-lg">
							<div className="p-8">
								<div className="text-center">
									<div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
										<FileText className="w-8 h-8 text-white" />
									</div>
									<h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent mb-4">
										{assessment.title}
									</h1>
									{assessment.description && (
										<p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto leading-relaxed">
											{assessment.description}
										</p>
									)}
									<div className="flex items-center justify-center space-x-8 text-sm">
										<div className="flex items-center space-x-2 bg-blue-50 px-4 py-2 rounded-full">
											<FileText className="w-4 h-4 text-blue-600" />
											<span className="text-blue-800 font-medium">{assessment.sections_count} sections</span>
										</div>
										<div className="flex items-center space-x-2 bg-purple-50 px-4 py-2 rounded-full">
											<CheckSquare className="w-4 h-4 text-purple-600" />
											<span className="text-purple-800 font-medium">{assessment.questions_count} questions</span>
										</div>
										<div className="flex items-center space-x-2">
											<span className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-medium ${
												assessment.active 
													? 'bg-green-100 text-green-800' 
													: 'bg-yellow-100 text-yellow-800'
											}`}>
												{assessment.active ? '✅ Active' : '📝 Draft'}
											</span>
										</div>
									</div>
								</div>
							</div>
						</Card>
					</div>

					{/* Sections */}
					<div className="space-y-8">
						{sections.map((section, sectionIndex) => (
							<div key={section.id}>
								<div className="flex items-center space-x-4 mb-6">
									<div className="w-8 h-8 bg-purple-600 text-white rounded-full flex items-center justify-center font-semibold text-sm">
										{sectionIndex + 1}
									</div>
									<h2 className="text-2xl font-semibold text-gray-900">
										{section.name}
									</h2>
								</div>

								<div className="space-y-6 ml-12">
									{section.questions && section.questions.length > 0 ? (
										section.questions
											.sort((a, b) => a.order - b.order)
											.map((question) => renderQuestionPreview(question))
									) : (
										<div className="text-center py-8 text-gray-500">
											No questions in this section
										</div>
									)}
								</div>
							</div>
						))}
					</div>

					{sections.length === 0 && (
						<div className="text-center py-12">
							<FileText className="w-16 h-16 text-gray-400 mx-auto mb-4" />
							<h3 className="text-lg font-medium text-gray-900 mb-2">
								No content available
							</h3>
							<p className="text-gray-500">
								This assessment doesn't have any sections or questions yet.
							</p>
						</div>
					)}

					{/* Footer */}
					{sections.length > 0 && (
						<div className="mt-12 pt-8 border-t border-gray-200">
							<div className="text-center">
								<p className="text-sm text-gray-500">
									This is a preview of the assessment. Responses cannot be submitted in preview mode.
								</p>
							</div>
						</div>
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