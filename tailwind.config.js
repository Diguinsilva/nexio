/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#5415AC',
          50: '#E8D9F8',
          100: '#D9C3F4',
          200: '#BB99EA',
          300: '#9D6FE0',
          400: '#7F45D6',
          500: '#5415AC',
          600: '#451189',
          700: '#360D66',
          800: '#270943',
          900: '#180520',
        },
        accent: {
          orange: '#ED4F22',
          pink: '#FD0685',
        },
      },
      backgroundImage: {
        'gradient-primary': 'linear-gradient(90deg, #5415AC 0%, #ED4F22 50%, #FD0685 100%)',
      },
    },
  },
  plugins: [],
}
