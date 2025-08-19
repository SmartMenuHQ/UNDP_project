"use client";

import { useState, useEffect } from "react";
import { RouteObject, useNavigate } from "react-router";
import { useAuth } from "../contexts/AuthContext";

function Login() {
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [error, setError] = useState<string | null>(null);
	const [isLoading, setIsLoading] = useState(false);
	const { login, isAuthenticated } = useAuth();
	const navigate = useNavigate();

	// Redirect if already authenticated
	useEffect(() => {
		if (isAuthenticated) {
			const redirectPath = localStorage.getItem('redirectAfterLogin') || '/app';
			localStorage.removeItem('redirectAfterLogin');
			navigate(redirectPath, { replace: true });
		}
	}, [isAuthenticated, navigate]);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		setError(null);
		setIsLoading(true);

		try {
			await login(email, password);
			// Navigation will happen via the useEffect hook
		} catch (err) {
			console.error('Login failed:', err);
			setError(err instanceof Error ? err.message : 'Login failed. Please try again.');
		} finally {
			setIsLoading(false);
		}
	};

	return (
		<section className="bg-gray-50 dark:bg-gray-900">
			<div className="flex flex-col items-center justify-center px-6 py-8 mx-auto md:h-screen lg:py-0">
				<a
					href="#"
					className="flex items-center mb-6 text-2xl font-semibold text-gray-900 dark:text-white"
				>
					<img className="w-24 h-24 mr-2" src="/undp.svg" alt="logo" />
				</a>
				<div className="w-full bg-white rounded-lg shadow dark:border md:mt-0 sm:max-w-md xl:p-0 dark:bg-gray-800 dark:border-gray-700">
					<div className="p-6 space-y-4 md:space-y-6 sm:p-8">
						<h1 className="text-xl font-bold leading-tight tracking-tight text-gray-900 md:text-2xl dark:text-white">
							Login to your account
						</h1>
						
						{error && (
							<div className="p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400" role="alert">
								{error}
							</div>
						)}

						<form className="space-y-4 md:space-y-6" onSubmit={handleSubmit}>
							<div>
								<label
									htmlFor="email"
									className="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
								>
									Email
								</label>
								<input
									type="email"
									name="email"
									id="email"
									value={email}
									onChange={(e) => setEmail(e.target.value)}
									className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-purple-600 focus:border-purple-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-purple-500 dark:focus:border-purple-500"
									placeholder="name@company.com"
									required
									disabled={isLoading}
								/>
							</div>
							<div>
								<label
									htmlFor="password"
									className="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
								>
									Password
								</label>
								<input
									type="password"
									name="password"
									id="password"
									value={password}
									onChange={(e) => setPassword(e.target.value)}
									placeholder="••••••••"
									className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-purple-600 focus:border-purple-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-purple-500 dark:focus:border-purple-500"
									required
									disabled={isLoading}
								/>
							</div>
							<button
								type="submit"
								disabled={isLoading}
								className="w-full text-white bg-purple-600 hover:bg-purple-700 focus:ring-4 focus:outline-none focus:ring-purple-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-purple-600 dark:hover:bg-purple-700 dark:focus:ring-purple-800 disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{isLoading ? 'Signing in...' : 'Login'}
							</button>
						</form>
					</div>
				</div>
			</div>
		</section>
	);
}

export const routePath = {
	path: "/app/login",
	Component: Login,
} as RouteObject;
