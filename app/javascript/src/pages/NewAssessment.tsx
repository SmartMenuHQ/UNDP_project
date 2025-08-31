"use client";

import { useState } from "react";
import { useNavigate } from "react-router";
import {
	Card,
	Label,
	TextInput,
	Textarea,
	Checkbox,
	Select,
	Alert,
} from "flowbite-react";
import { ArrowLeft, Save, AlertCircle, CheckCircle } from "lucide-react";
import { RouteObject } from "react-router";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { createAssessment } from "../api/assessments";

interface NewAssessmentForm {
	title: string;
	description: string;
	active: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
}

// Dummy countries for now - in real app, fetch from API
const countries = [
	{ value: "US", label: "United States" },
	{ value: "UK", label: "United Kingdom" },
	{ value: "CA", label: "Canada" },
	{ value: "AU", label: "Australia" },
	{ value: "DE", label: "Germany" },
	{ value: "FR", label: "France" },
];

export default function NewAssessment() {
	const navigate = useNavigate();
	const [isLoading, setIsLoading] = useState(false);
	const [error, setError] = useState<string | null>(null);
	const [success, setSuccess] = useState<string | null>(null);
	const [formData, setFormData] = useState<NewAssessmentForm>({
		title: "",
		description: "",
		active: true,
		has_country_restrictions: false,
		restricted_countries: [],
	});

	const handleInputChange = (field: keyof NewAssessmentForm, value: any) => {
		setFormData(prev => ({
			...prev,
			[field]: value
		}));
		// Clear error and success when user starts typing
		if (error) setError(null);
		if (success) setSuccess(null);
	};

	const handleCountryChange = (countryValue: string) => {
		setFormData(prev => ({
			...prev,
			restricted_countries: prev.restricted_countries.includes(countryValue)
				? prev.restricted_countries.filter(c => c !== countryValue)
				: [...prev.restricted_countries, countryValue]
		}));
	};

	const validateForm = (): boolean => {
		if (!formData.title.trim()) {
			setError("Assessment title is required");
			return false;
		}
		if (formData.title.trim().length < 3) {
			setError("Assessment title must be at least 3 characters long");
			return false;
		}
		return true;
	};

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		
		if (!validateForm()) return;

		setIsLoading(true);
		setError(null);

		try {
			const newAssessment = await createAssessment(formData);
			
			// Show success message
			setSuccess('Assessment created successfully!');
			
			// Navigate back to assessments list after a short delay
			setTimeout(() => {
				navigate('/app/assessments');
			}, 1500);
		} catch (err) {
			console.error('Error creating assessment:', err);
			setError(err instanceof Error ? err.message : 'Failed to create assessment');
		} finally {
			setIsLoading(false);
		}
	};

	const handleCancel = () => {
		navigate(-1);
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
						<button 
							onClick={handleCancel}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<ArrowLeft className="w-4 h-4 mr-2" />
							Back
						</button>
						<h1 className="text-2xl font-bold text-gray-900">Create New Assessment</h1>
					</div>
				</div>

				{/* Main Content */}
				<div className="flex justify-center">
					<div className="max-w-2xl w-full">
						<form onSubmit={handleSubmit} className="space-y-6">
							{/* Error Alert */}
							{error && (
								<Alert color="failure" icon={AlertCircle}>
									{error}
								</Alert>
							)}

							{/* Success Alert */}
							{success && (
								<Alert color="success" icon={CheckCircle}>
									{success}
								</Alert>
							)}

							{/* Title Field */}
							<div>
								<Label htmlFor="title" value="Assessment Title" className="mb-2 block" />
								<TextInput
									id="title"
									type="text"
									required
									placeholder="Enter assessment title"
									value={formData.title}
									onChange={(e) => handleInputChange('title', e.target.value)}
									className="w-full"
									disabled={isLoading || !!success}
								/>
							</div>

							{/* Description Field */}
							<div>
								<Label htmlFor="description" value="Description (Optional)" className="mb-2 block" />
								<Textarea
									id="description"
									placeholder="Enter assessment description"
									rows={4}
									value={formData.description}
									onChange={(e) => handleInputChange('description', e.target.value)}
									className="w-full"
									disabled={isLoading || !!success}
								/>
							</div>

							{/* Active Status */}
							<div className="flex items-start space-x-3">
								<Checkbox
									id="active"
									checked={formData.active}
									onChange={(e) => handleInputChange('active', e.target.checked)}
									disabled={isLoading || !!success}
								/>
								<div className="flex flex-col">
									<Label htmlFor="active" className="text-sm font-medium text-gray-900">
										Active Assessment
									</Label>
									<p className="text-sm text-gray-500">
										Active assessments are visible to users and can be taken
									</p>
								</div>
							</div>

							{/* Country Restrictions */}
							<div className="space-y-4">
								<div className="flex items-start space-x-3">
									<Checkbox
										id="country_restrictions"
										checked={formData.has_country_restrictions}
										onChange={(e) => handleInputChange('has_country_restrictions', e.target.checked)}
										disabled={isLoading || !!success}
									/>
									<div className="flex flex-col">
										<Label htmlFor="country_restrictions" className="text-sm font-medium text-gray-900">
											Restrict by Country
										</Label>
										<p className="text-sm text-gray-500">
											Limit access to specific countries only
										</p>
									</div>
								</div>

								{/* Country Selection */}
								{formData.has_country_restrictions && (
									<div className="ml-6 space-y-2">
										<Label value="Select Restricted Countries" className="text-sm font-medium" />
										<div className="grid grid-cols-2 gap-2 p-4 bg-gray-50 rounded-lg">
											{countries.map((country) => (
												<div key={country.value} className="flex items-center space-x-2">
													<Checkbox
														id={`country_${country.value}`}
														checked={formData.restricted_countries.includes(country.value)}
														onChange={() => handleCountryChange(country.value)}
														disabled={isLoading || !!success}
													/>
													<Label 
														htmlFor={`country_${country.value}`} 
														className="text-sm text-gray-700"
													>
														{country.label}
													</Label>
												</div>
											))}
										</div>
									</div>
								)}
							</div>

							{/* Submit Buttons */}
							<div className="flex items-center justify-end space-x-4 pt-6 border-t border-gray-200">
								<button 
									type="button"
									onClick={handleCancel}
									disabled={isLoading || !!success}
									className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
								>
									Cancel
								</button>
								<button 
									type="submit" 
									disabled={isLoading || !!success}
									className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
								>
									<Save className="w-4 h-4 mr-2" />
									{isLoading ? 'Creating...' : 'Create Assessment'}
								</button>
							</div>
						</form>
					</div>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments/new",
	Component: NewAssessment,
} as RouteObject;