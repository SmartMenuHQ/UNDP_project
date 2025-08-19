"use client";

import { useState, useEffect } from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import {
	Card,
	Button,
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeadCell,
	TableRow,
	Alert,
} from "flowbite-react";
import { ArrowLeft, Plus, Edit, Trash2, FileText, AlertCircle } from "lucide-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { fetchAssessment } from "../api/assessments";

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

interface AssessmentSection {
	id: number;
	name: string;
	order: number;
	is_conditional: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
	questions_count: number;
	created_at: string;
	updated_at: string;
}

export default function AssessmentSections() {
	const { id } = useParams();
	const navigate = useNavigate();
	const [assessment, setAssessment] = useState<Assessment | null>(null);
	const [sections, setSections] = useState<AssessmentSection[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		const loadAssessment = async () => {
			if (!id) return;
			
			try {
				const data = await fetchAssessment(Number(id));
				setAssessment(data);
				// TODO: Fetch sections once API is set up
				setSections([]);
			} catch (err) {
				console.error('Failed to fetch assessment:', err);
				setError(err instanceof Error ? err.message : 'Failed to load assessment');
			} finally {
				setLoading(false);
			}
		};

		loadAssessment();
	}, [id]);

	const handleBack = () => {
		navigate('/app');
	};

	const handleAddSection = () => {
		// TODO: Navigate to add section page or show modal
		console.log('Add section');
	};

	const handleEditSection = (sectionId: number) => {
		// TODO: Navigate to edit section page
		console.log('Edit section:', sectionId);
	};

	if (loading) {
		return (
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>
				<DashboardLayout.Content>
					<div className="flex items-center justify-center min-h-96">
						<div className="text-center">
							<div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
							<p className="text-gray-600">Loading assessment...</p>
						</div>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		);
	}

	if (error) {
		return (
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>
				<DashboardLayout.Content>
					<div className="flex items-center justify-center min-h-96">
						<Alert color="failure" icon={AlertCircle}>
							{error}
						</Alert>
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
				{/* Header */}
				<div className="flex items-center justify-between mb-8">
					<div className="flex items-center space-x-4">
						<button 
							onClick={handleBack}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<ArrowLeft className="w-4 h-4 mr-2" />
							Back to Assessments
						</button>
						<div>
							<h1 className="text-2xl font-bold text-gray-900">{assessment?.title}</h1>
							<p className="text-gray-600">Manage sections and questions</p>
						</div>
					</div>
					<button 
						onClick={handleAddSection}
						className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
					>
						<Plus className="w-4 h-4 mr-2" />
						Add Section
					</button>
				</div>

				{/* Assessment Info */}
				<div className="mb-6">
					<Card className="shadow-none">
						<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
							<div>
								<h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Status</h3>
								<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mt-1 ${
									assessment?.active 
										? 'bg-green-100 text-green-800' 
										: 'bg-yellow-100 text-yellow-800'
								}`}>
									{assessment?.active ? 'Active' : 'Draft'}
								</span>
							</div>
							<div>
								<h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Sections</h3>
								<p className="text-lg font-semibold text-gray-900">{assessment?.sections_count || 0}</p>
							</div>
							<div>
								<h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Questions</h3>
								<p className="text-lg font-semibold text-gray-900">{assessment?.questions_count || 0}</p>
							</div>
						</div>
						{assessment?.description && (
							<div className="mt-4 pt-4 border-t border-gray-200">
								<h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider mb-2">Description</h3>
								<p className="text-gray-700">{assessment.description}</p>
							</div>
						)}
					</Card>
				</div>

				{/* Sections Table */}
				<div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
					<div className="px-6 py-4 border-b border-gray-200">
						<h2 className="text-lg font-semibold text-gray-900">Assessment Sections</h2>
						<p className="text-sm text-gray-600">Manage the sections and structure of your assessment</p>
					</div>
					
					{sections.length === 0 ? (
						<div className="text-center py-12">
							<FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
							<h3 className="text-lg font-medium text-gray-900 mb-2">No sections yet</h3>
							<p className="text-gray-600 mb-6">Get started by adding your first section to this assessment.</p>
							<button 
								onClick={handleAddSection}
								className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors mx-auto"
							>
								<Plus className="w-4 h-4 mr-2" />
								Add First Section
							</button>
						</div>
					) : (
						<Table>
							<TableHead>
								<TableRow className="bg-gray-50 border-b border-gray-200">
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Section Name
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Order
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Questions
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Restrictions
									</TableHeadCell>
									<TableHeadCell className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										<span className="sr-only">Actions</span>
									</TableHeadCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{sections.map((section, index) => (
									<TableRow key={section.id} className={`${index !== sections.length - 1 ? 'border-b border-gray-200' : ''} hover:bg-gray-50 transition-colors duration-150`}>
										<TableCell className="px-6 py-4">
											<div className="flex items-center space-x-3">
												<div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
													<FileText className="w-4 h-4 text-gray-600" />
												</div>
												<span className="font-medium text-gray-900">{section.name}</span>
											</div>
										</TableCell>
										<TableCell className="px-6 py-4 text-gray-500">
											{section.order}
										</TableCell>
										<TableCell className="px-6 py-4 text-gray-500">
											{section.questions_count} questions
										</TableCell>
										<TableCell className="px-6 py-4">
											{section.has_country_restrictions ? (
												<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
													Country Restricted
												</span>
											) : (
												<span className="text-gray-500">No restrictions</span>
											)}
										</TableCell>
										<TableCell className="px-6 py-4">
											<div className="flex items-center space-x-2">
												<button 
													onClick={() => handleEditSection(section.id)}
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
								))}
							</TableBody>
						</Table>
					)}
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments/:id/sections",
	Component: AssessmentSections,
} as RouteObject;