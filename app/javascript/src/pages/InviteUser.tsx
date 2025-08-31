"use client";

import React, { useState, useEffect } from 'react';
import { RouteObject, useNavigate } from 'react-router';
import { Card, Button } from 'flowbite-react';
import { UserPlus, Mail, AlertCircle, CheckCircle, ArrowLeft } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import DashboardLayout from '../layouts/DashboardLayout';
import ApplicationSidebar from '../components/Sidebar/Sidebar';
import RouteGuard from '../components/RouteGuard';

interface Country {
	id: number;
	name: string;
	code: string;
	active: boolean;
}

function InviteUser() {
	const { token, user } = useAuth();
	const navigate = useNavigate();
	const [formData, setFormData] = useState({
		email_address: '',
		first_name: '',
		last_name: '',
		country_id: '',
		admin: false
	});
	const [countries, setCountries] = useState<Country[]>([]);
	const [loading, setLoading] = useState(false);
	const [countriesLoading, setCountriesLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [success, setSuccess] = useState<string | null>(null);

	useEffect(() => {
		// Only load countries if user is admin to prevent API errors before redirect
		if (user?.user?.admin) {
			fetchCountries();
		} else {
			setCountriesLoading(false);
		}
	}, [user]);

	const fetchCountries = async () => {
		if (!token) return;

		try {
			const response = await fetch('/api/v1/countries', {
				headers: {
					'Authorization': `Bearer ${token}`,
					'Content-Type': 'application/json',
				},
			});

			const result = await response.json();
			
			if (result.status === 'ok') {
				setCountries(result.data.countries || []);
			} else {
				console.error('Failed to fetch countries:', result.errors);
			}
		} catch (err) {
			console.error('Error fetching countries:', err);
		} finally {
			setCountriesLoading(false);
		}
	};

	const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
		const { name, value, type } = e.target;
		setFormData(prev => ({
			...prev,
			[name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
		}));
	};

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		if (!token) return;

		setLoading(true);
		setError(null);
		setSuccess(null);

		try {
			const response = await fetch('/api/v1/admin/users/invite', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': `Bearer ${token}`,
				},
				body: JSON.stringify({ user: formData }),
			});

			const result = await response.json();

			if (response.ok && result.status === 'ok') {
				setSuccess(`Invitation sent successfully to ${formData.email_address}!`);
				setFormData({
					email_address: '',
					first_name: '',
					last_name: '',
					country_id: '',
					admin: false
				});
			} else {
				let errorMessage = 'Failed to send invitation';
				
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
			console.error('Invitation error:', err);
			setError(err instanceof Error ? err.message : 'An unexpected error occurred');
		} finally {
			setLoading(false);
		}
	};

	return (
		<RouteGuard requireAdmin={true}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				<div className="max-w-2xl mx-auto">
					<div className="space-y-6">
						{/* Header */}
						<div className="mb-6">
							<h1 className="text-2xl font-semibold text-gray-900">Invite User</h1>
							<p className="text-gray-600 mt-1">Send an invitation to a new user to join the platform</p>
						</div>

			{/* Success Message */}
			{success && (
				<div className="p-4 bg-green-50 border border-green-200 rounded-lg flex items-center">
					<CheckCircle className="w-5 h-5 text-green-600 mr-3" />
					<span className="text-green-800">{success}</span>
				</div>
			)}

			{/* Error Message */}
			{error && (
				<div className="p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
					<AlertCircle className="w-5 h-5 text-red-600 mr-3" />
					<span className="text-red-800">{error}</span>
				</div>
			)}

			{/* Invite Form */}
			<Card className="border border-gray-200 shadow-none">
				<form onSubmit={handleSubmit} className="space-y-6">
					<div className="flex items-center mb-4">
						<UserPlus className="w-6 h-6 text-purple-600 mr-2" />
						<h2 className="text-xl font-medium text-gray-900">User Information</h2>
					</div>

					<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
						{/* First Name */}
						<div>
							<label htmlFor="first_name" className="block text-sm font-medium text-gray-700 mb-2">
								First Name *
							</label>
							<input
								type="text"
								id="first_name"
								name="first_name"
								value={formData.first_name}
								onChange={handleInputChange}
								required
								className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
								placeholder="Enter first name"
								disabled={loading}
							/>
						</div>

						{/* Last Name */}
						<div>
							<label htmlFor="last_name" className="block text-sm font-medium text-gray-700 mb-2">
								Last Name *
							</label>
							<input
								type="text"
								id="last_name"
								name="last_name"
								value={formData.last_name}
								onChange={handleInputChange}
								required
								className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
								placeholder="Enter last name"
								disabled={loading}
							/>
						</div>
					</div>

					{/* Email */}
					<div>
						<label htmlFor="email_address" className="block text-sm font-medium text-gray-700 mb-2">
							Email Address *
						</label>
						<div className="relative">
							<Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
							<input
								type="email"
								id="email_address"
								name="email_address"
								value={formData.email_address}
								onChange={handleInputChange}
								required
								className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
								placeholder="user@example.com"
								disabled={loading}
							/>
						</div>
						<p className="text-xs text-gray-500 mt-1">
							An invitation email will be sent to this address
						</p>
					</div>

					{/* Country */}
					<div>
						<label htmlFor="country_id" className="block text-sm font-medium text-gray-700 mb-2">
							Country *
						</label>
						<select
							id="country_id"
							name="country_id"
							value={formData.country_id}
							onChange={handleInputChange}
							required
							className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
							disabled={loading || countriesLoading}
						>
							<option value="">Select a country</option>
							{countries.map((country) => (
								<option key={country.id} value={country.id}>
									{country.name} ({country.code})
								</option>
							))}
						</select>
						{countriesLoading && (
							<p className="text-xs text-gray-500 mt-1">Loading countries...</p>
						)}
					</div>

					{/* Admin Checkbox */}
					<div className="flex items-center">
						<input
							type="checkbox"
							id="admin"
							name="admin"
							checked={formData.admin}
							onChange={handleInputChange}
							disabled={loading}
							className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500 focus:ring-2"
						/>
						<label htmlFor="admin" className="ml-2 text-sm text-gray-700">
							Grant admin privileges
						</label>
						<p className="ml-2 text-xs text-gray-500">
							(Admin users can manage assessments and invite other users)
						</p>
					</div>

					{/* Submit Button */}
					<div className="flex justify-end space-x-3 pt-4 border-t border-gray-200">
						<button
							type="button"
							onClick={() => navigate('/app')}
							className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
							disabled={loading}
						>
							Cancel
						</button>
						<button
							type="submit"
							disabled={loading || countriesLoading}
							className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
						>
							{loading ? (
								<>
									<div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
									Sending Invitation...
								</>
							) : (
								<>
									<Mail className="w-4 h-4 mr-2" />
									Send Invitation
								</>
							)}
						</button>
					</div>
				</form>
			</Card>
					</div>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
		</RouteGuard>
	);
}

export const routePath = {
	path: "/app/users/invite",
	Component: InviteUser,
} as RouteObject;