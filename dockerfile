# Stage 1: Build the application with dev dependencies and run tests/linting
# Using node:18-alpine as specified in package.json engines for a lightweight image
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first
# This allows Docker to cache the npm install step if only source code changes
COPY package*.json ./

# Install all dependencies (including devDependencies for testing and linting)
# 'npm ci' is used for clean, reproducible installs in CI environments
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Run quality checks (tests and linting) during the build process
# If any of these commands fail, the Docker build will fail, acting as a quality gate
RUN npm test
RUN npm run lint

# Stage 2: Create the final, lightweight production image
# Using the same base image for consistency and small size
FROM node:18-alpine AS production

# Set the working directory for the production application
WORKDIR /app

# Copy only the production dependencies from the 'builder' stage
# This ensures that devDependencies (like Jest, ESLint) are not included in the final image
COPY --from=builder /app/node_modules ./node_modules

# Copy only the essential application files for production
# This includes server.js and the public directory for the frontend
COPY server.js ./
COPY public ./public

# Expose the port on which the application will listen
# Your server.js listens on process.env.PORT or defaults to 3000
EXPOSE 3000

# Define the command to run the application when the container starts
# This uses the 'start' script defined in your package.json
CMD ["npm", "start"]
