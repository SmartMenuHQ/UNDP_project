import { createRoot } from 'react-dom/client'
import App from '@/components/App'

// Initialize React app
const rootElement = document.getElementById('react-app')

if (rootElement) {
  const root = createRoot(rootElement)

  root.render(<App />)

  // Development logging
  if (import.meta.env.DEV) {
    console.log('🚀 React app mounted successfully!')
  }
} else {
  console.error('Could not find root element with id "react-app"')
}
