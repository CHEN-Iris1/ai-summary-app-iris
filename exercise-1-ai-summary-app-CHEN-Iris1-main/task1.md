## Section 1: Overview

Next.js is a React framework that provides server-side rendering, API routes, and file-based routing out of the box. It offers a great developer experience with fast refresh and optimized production builds. 

Here is the folder architecture of our app:
- `my-app/` — Root of the Next.js project.
- `my-app/app/` — Frontend (App Router): pages, layouts, client and server components.
- `my-app/app/api/` — Backend API routes (serverless functions): endpoints such as `upload`, `extract`, `summarize`, `health`, etc.
- `my-app/app/components/` — Reusable UI components (e.g. FileUploader, FileList, DocumentViewer, Header, StatusMessage).
- `my-app/app/lib/` — Shared helpers and services (API clients, configuration, custom hooks).
- `my-app/public/` — Static assets (images, icons) served directly.
- `my-app/next.config.js`, `my-app/package.json` — Project configuration and dependencies.
- `.env` (local) — Environment variables for Supabase and model keys (do not commit secrets to GitHub).


You will need accounts for the following services (all have free tiers):
- **GitHub** (for Codespaces + repo): Version control and cloud development environment
- **Vercel**: Hosting platform for Next.js applications
- **Supabase**: Open-source Firebase alternative with storage capabilities


## Section 2: Create a simple Next.JS app

GitHub Codespaces provides a cloud-based development environment with VS Code, git, and all necessary tools pre-installed. Creating a repository first gives you version control from day one, and Codespaces eliminates "works on my machine" issues since everyone develops in the same Linux container.

1. Create a new GitHub repository, e.g. `ai-summary-app`.
2. Click **Code → Codespaces → Create codespace on main**.

### Create .gitignore file
A `.gitignore` file tells Git which files and directories to ignore when creating commits. Adding it early prevents accidental commits of large generated folders (like `node_modules`), editor or OS artifacts (like `.DS_Store`), and most importantly, secret or environment files (like `.env`). This keeps the repository small, avoids leaking credentials, and makes collaboration safer and cleaner.

1. In the VSCode Explorer (left sidebar), click the **New File** icon (📄+) next to your repository name
2. Name the file `.gitignore`
3. Copy and paste this content into the file:

```gitignore
# Next.js build outputs
.next/            # Production build output
out/              # Static export output
build/            # Alternative build folder

# Node.js dependencies
node_modules/     # External packages installed by npm (can be re-downloaded)

# Environment files containing secrets
.env
.env*.local
!.env.example

# Testing
coverage/

# OS and editor specific files
.DS_Store         # macOS folder metadata
.vscode/          # VS Code settings (optional—team preference)
.vercel           # Vercel CLI local cache

# Debug logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
```

4. Save the file: **Ctrl+S** (Windows/Linux) or **Cmd+S** (Mac)

The `.gitignore` file above excludes:
- `node_modules/`: This folder contains all installed npm packages—no need to track. It size can be 100MB+, and anyone can reinstall with `npm install`. Do not commit this folder to GitHub.
- `.env*.local`: Contains secrets—exposing this is a security incident
- `.next/`: This folder is generated when building the Next.js app. 

We will now commit the `.gitignore` and `.env.example` files to the repository to establish good git hygiene from the start.

```bash
# Stage all changed files for commit
git add .gitignore

# Create a commit with a descriptive message
git commit -m "chore: add gitignore"

# Push commit to GitHub remote repository
git push origin main
```

## Section 3: Create the Next.js app

### Scaffold Next.js app

In this section, you'll create a new Next.js application, install dependencies, and run it locally to verify everything works before deploying.

To create a Next.js app with TypeScript and Tailwind CSS in one step, use:

```bash
npx create-next-app@latest my-app --typescript --tailwind
```

Accept the default settings

Run the app.

```bash
cd my-app
npm run dev -- --port 3000
```

The `--port 3000` flag (optional) starts the dev server on port 3000 (default).
Open the forwarded port (Codespaces "Ports" tab) and confirm the page loads.

Here is the default Next.js starter page you should see:

> [SCREENSHOT PLACEHOLDER — After running the dev server, capture the Next.js starter page and save a screenshot here.]



### Add a minimal UI 

The default Next.js template includes example code we don't need. We'll replace it with a minimal interface to verify the frontend works before adding features. This incremental approach makes debugging easier—start simple, add complexity gradually.

Edit `my-app/app/page.tsx` and replace with something tiny:

```typescript
'use client'

import { useState } from "react";

export default function Home() {
  const [status, setStatus] = useState("Frontend running");

  return (
    <div style={{ fontFamily: "system-ui", padding: 24, maxWidth: 800 }}>
      <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '1rem', color: '#0070f3' }}>AI Summary App</h1>
      <p>{status}</p>
      <p>Next: deploy this to Vercel, then add API routes.</p>
    </div>
  );
}
```

This component is the starting page of the AI Summary App. When the page loads, it displays a welcome heading that says "AI Summary App" and shows a status message saying "Frontend running". 

Visit the app in your browser again to verify the changes took effect.

> [SCREENSHOT PLACEHOLDER — After updating `app/page.tsx`, capture a screenshot of the minimal UI and save it here.]

Start a new terminal
Let's commit this frontend scaffold as our first feature:

```bash
git add .
git commit -m "feat(frontend): scaffold Next.js app with basic landing UI"
```

### Deploy to Vercel

Deploying early verifies your build works and gives you a live URL to test. Vercel automatically detects Next.js projects, builds them, and deploys them globally. You can deploy via the dashboard (more visual) or CLI (faster for repeat deployments).

We will use the Vercel CLI for deployment. Open a terminal and login with your Vercel account.

First, install the Vercel CLI if you haven't already:
```bash
npm i -g vercel
```

Then login to Vercel:

```bash
vercel login
```

> [SCREENSHOT PLACEHOLDER — After logging into Vercel (or running `vercel login`), capture the login prompt and save a screenshot here.]

Now deploy the app from the `my-app/` folder

```bash
cd my-app
vercel
```

Accept the default settings.

The terminal will show a deployment URL once complete.

You can "Ctrl+Click" the URL to open the deployed app in a new browser tab.
 
In the terminal running your NextJS app, stop the local server with `Ctrl+C` to stop the app.

## Section 4: Add API Routes

### Understand how API Routes work in Next.js
Now, we will build the backend using Next.js API Routes.

Next.js API Routes are serverless functions that run on the server. Any file in `app/api/` becomes an API endpoint:
- `app/api/health/route.ts` → `/api/health`
- `app/api/upload/route.ts` → `/api/upload`


### Create health check endpoint

**Create `app/api/health/route.ts` file:**

In NextJS apps, the API routes are used define different endpoints for handling backend functionalities.  We'll create a simple health check endpoint to verify the backend is running.

1. In VSCode Explorer, navigate to `my-app/app`
2. Create folder: `api`
3. Inside `api`, create folder: `health`
4. Inside `health`, create file: `route.ts`
5. Add this code:

```typescript
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    ok: true,
    message: "Next.js backend is running"
  });
}
```

This code defines a GET endpoint at `/api/health` that responds with a JSON object indicating the backend is operational.


### Test locally

From `my-app` directory:

```bash
npm run dev
```

Now open a terminal and test:

```bash
curl -s http://localhost:3000/api/health | jq
```

You should see:

`{"ok": true, "message": "Next.js backend is running"}`.



### Deploy to Vercel

Update  your app in under the `my-app` folder.
```bash
vercel --prod
```

Visit `https://your-deployment-url/api/health` to verify the backend works in production.

The webpage should show:

`{"ok": true, "message": "Next.js backend is running"}`.


### Commit checkpoint

Commit the changes and push the change to GitHub.

```bash
git add app/api
git commit -m "feat(backend): add health check API route"
git push 
```

## Section 5: Connect Frontend to Backend

### Add a Backend Health Check button

Let's add a button to the frontend that calls the backend health check API route we just created. This verifies that the frontend and backend can communicate properly.

In `app/page.tsx`, add a call to the backend.

Update `app/page.tsx` as follows:

```typescript
'use client'

import { useState } from "react";

export default function Home() {
  const [status, setStatus] = useState("Frontend running");

  async function checkBackend() {
    setStatus("Checking backend...");
    const res = await fetch('/api/health');
    const data = await res.json();
    setStatus(`Backend says: ${data.message}`);
  }


  return (
    <div style={{ fontFamily: "system-ui", padding: 24, maxWidth: 800 }}>
      <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '1rem', color: '#1d324b' }}>AI Summary App</h1>
      <button 
        onClick={checkBackend}
        className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded"
      >
        Check backend
      </button>
      <p style={{ marginTop: 12 }}>{status}</p>
    </div>
  );
}
```

In the above code, we added a button that, when clicked, calls the `checkBackend` function. This function makes a fetch request to the `/api/health` endpoint and updates the status message based on the response.

Run the app locally to test:

```bash
npm run dev
```

Open `http://localhost:3000` and click the **Check backend** button. It should report the backend status.

Example output:

> [SCREENSHOT PLACEHOLDER — After clicking the backend check button, capture the health-check output and save a screenshot here.]


**Commit checkpoint:**

```bash
git add app/page.tsx
git commit -m "feat(frontend): add backend health check button"
git push
```

This is about the process of task1.
First，following the steps of this md file. And correct the code of adding the frontend interface and botton. The picture is following:
![alt text](b001d178be4511f4ce1ff01aca886373.png)

After clicking the botton, the interface becomes:
![alt text](b81640f6f57d7face97e01c8c96c2ea3.png)
