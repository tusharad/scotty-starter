// Service Worker mock for Scotty Starter 2.0 GitHub Pages Static Demo
// Simulates the Scotty 0.30 routing engine, RFC 7807 error boundaries, and SQLite HTMX partials.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

let clickCounter = 0;
let nextPostId = 3;
let posts = [
  { id: 2, title: "Haskell in Production: Warp & WAI" },
  { id: 1, title: "Getting Started with Scotty 0.30" }
];

function escapeHtml(str) {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function renderPost(post) {
  return `<div class="post-card" id="post-${post.id}">
  <div class="post-info">
    <span class="post-id-chip">#${post.id}</span>
    <span class="post-title">${escapeHtml(post.title)}</span>
  </div>
  <button class="btn-del" hx-delete="/partials/posts/${post.id}" hx-target="#post-${post.id}" hx-swap="outerHTML" hx-confirm="Delete this record from SQLite database?">Delete</button>
</div>`;
}

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  const pathname = url.pathname;

  // 1. Path Parameters: /api/tour/path-params/:category/:id
  const pathParamMatch = pathname.match(/\/api\/tour\/path-params\/([^/]+)\/([^/]+)/);
  if (pathParamMatch && event.request.method === 'GET') {
    const category = decodeURIComponent(pathParamMatch[1]);
    const id = parseInt(pathParamMatch[2], 10) || pathParamMatch[2];
    const data = {
      concept: "Path Parameters",
      category: category,
      id: id
    };
    event.respondWith(
      new Response(JSON.stringify(data, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json; charset=utf-8" }
      })
    );
    return;
  }

  // 2. Query Parameters: /api/tour/query-params
  if (pathname.includes('/api/tour/query-params') && event.request.method === 'GET') {
    const rawQueries = [];
    url.searchParams.forEach((val, key) => {
      rawQueries.push([key, val]);
    });
    const filter = url.searchParams.get('filter');
    const limit = url.searchParams.get('limit') ? parseInt(url.searchParams.get('limit'), 10) : null;
    const data = {
      concept: "Query Parameters",
      filter: filter,
      limit: limit,
      raw_queries: rawQueries
    };
    event.respondWith(
      new Response(JSON.stringify(data, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json; charset=utf-8" }
      })
    );
    return;
  }

  // 3. JSON Request Body: /api/tour/json-body
  if (pathname.includes('/api/tour/json-body') && event.request.method === 'POST') {
    event.respondWith(
      event.request.json().then((payload) => {
        const data = {
          concept: "JSON Deserialization",
          parsed: payload
        };
        return new Response(JSON.stringify(data, null, 2), {
          status: 201,
          headers: { "Content-Type": "application/json; charset=utf-8" }
        });
      }).catch((err) => {
        return new Response(JSON.stringify({
          type: "about:blank",
          title: "Malformed JSON Request",
          status: 400,
          detail: err.message
        }, null, 2), {
          status: 400,
          headers: { "Content-Type": "application/problem+json; charset=utf-8" }
        });
      })
    );
    return;
  }

  // 4. Form Submissions: /api/tour/form-params
  if (pathname.includes('/api/tour/form-params') && event.request.method === 'POST') {
    event.respondWith(
      event.request.text().then((rawText) => {
        const params = new URLSearchParams(rawText);
        const username = params.get('username') || "";
        const email = params.get('email') || "";
        const newsletter = params.get('newsletter') ? true : null;
        const data = {
          concept: "Form Data Parsing",
          username: username,
          email: email,
          newsletter: newsletter
        };
        return new Response(JSON.stringify(data, null, 2), {
          status: 201,
          headers: { "Content-Type": "application/json; charset=utf-8" }
        });
      })
    );
    return;
  }

  // 5. Headers & Cookies: /api/tour/headers-and-cookies
  if (pathname.includes('/api/tour/headers-and-cookies') && event.request.method === 'GET') {
    const userAgent = event.request.headers.get('User-Agent') || navigator.userAgent;
    const cookieHeader = event.request.headers.get('Cookie') || 'visited=true';
    const data = {
      concept: "Headers & Cookies",
      user_agent: userAgent,
      cookie: cookieHeader.includes('visited') ? 'visited=true' : 'visited=true'
    };
    event.respondWith(
      new Response(JSON.stringify(data, null, 2), {
        status: 200,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Set-Cookie": "visited=true; Path=/; SameSite=Lax",
          "X-Scotty-Powered-By": "Scotty 0.30 (Haskell / GitHub Pages Mock)"
        }
      })
    );
    return;
  }

  // 6. Dynamic HTTP Status Codes: /api/tour/status-codes/:code
  const statusCodeMatch = pathname.match(/\/api\/tour\/status-codes\/(\d+)/);
  if (statusCodeMatch && event.request.method === 'GET') {
    const code = parseInt(statusCodeMatch[1], 10);
    if (code === 204) {
      event.respondWith(new Response(null, { status: 204 }));
      return;
    }
    const data = {
      concept: "Status Codes",
      status_code: code
    };
    event.respondWith(
      new Response(JSON.stringify(data, null, 2), {
        status: code,
        headers: { "Content-Type": "application/json; charset=utf-8" }
      })
    );
    return;
  }

  // 7. RFC 7807 Error Boundaries: /api/tour/errors/:type
  const errorMatch = pathname.match(/\/api\/tour\/errors\/([^/]+)/);
  if (errorMatch && event.request.method === 'GET') {
    const errType = errorMatch[1];
    let problem;
    if (errType === 'missing-query') {
      problem = {
        type: "about:blank",
        title: "Missing Query Parameter",
        status: 400,
        detail: "Missing: required_param"
      };
    } else {
      problem = {
        type: "about:blank",
        title: "Parameter Parse Failure",
        status: 400,
        detail: "Cannot parse: numeric_field (expected Int)"
      };
    }
    event.respondWith(
      new Response(JSON.stringify(problem, null, 2), {
        status: 400,
        headers: { "Content-Type": "application/problem+json; charset=utf-8" }
      })
    );
    return;
  }

  // 8. Redirection: /api/tour/redirect-to-docs
  if (pathname.includes('/api/tour/redirect-to-docs')) {
    event.respondWith(
      Response.redirect(new URL('docs.html', event.request.url).href, 302)
    );
    return;
  }

  // 9. Health Check: /healthz
  if (pathname.includes('/healthz') && event.request.method === 'GET') {
    const health = {
      status: "ok",
      app: "scotty-starter",
      version: "0.2.0",
      runtime: "GHC 9.10.3 / Warp / GitHub Pages Static",
      pool_stats: {
        available: 10,
        in_use: 0
      }
    };
    event.respondWith(
      new Response(JSON.stringify(health, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json; charset=utf-8" }
      })
    );
    return;
  }

  // 10. HTMX Counter Partial: /partials/counter
  if (pathname.includes('/partials/counter') && event.request.method === 'POST') {
    clickCounter++;
    const html = `<button class="btn-secondary" id="counter-btn" hx-post="/partials/counter" hx-target="#counter-btn" hx-swap="outerHTML">Server Clicks: ${clickCounter} ⚡</button>`;
    event.respondWith(
      new Response(html, {
        status: 200,
        headers: { "Content-Type": "text/html; charset=utf-8" }
      })
    );
    return;
  }

  // 11. HTMX Posts Search: /partials/posts/search?q=...
  if (pathname.includes('/partials/posts/search') && event.request.method === 'GET') {
    const q = (url.searchParams.get('q') || "").toLowerCase();
    const filtered = posts.filter(p => p.title.toLowerCase().includes(q));
    let html = "";
    if (filtered.length === 0) {
      html = `<div style="grid-column: 1 / -1; padding: 2rem; text-align: center; color: var(--text-dim);">No matching SQLite records found for "${escapeHtml(q)}".</div>`;
    } else {
      html = filtered.map(renderPost).join("\n");
    }
    event.respondWith(
      new Response(html, {
        status: 200,
        headers: { "Content-Type": "text/html; charset=utf-8" }
      })
    );
    return;
  }

  // 12. HTMX Add Post: POST /partials/posts
  if (pathname.endsWith('/partials/posts') && event.request.method === 'POST') {
    event.respondWith(
      event.request.text().then((rawText) => {
        const params = new URLSearchParams(rawText);
        const title = (params.get('title') || "Untitled Entry").trim();
        const newPost = { id: nextPostId++, title: title };
        posts.unshift(newPost);
        return new Response(renderPost(newPost), {
          status: 200,
          headers: { "Content-Type": "text/html; charset=utf-8" }
        });
      })
    );
    return;
  }

  // 13. HTMX Delete Post: DELETE /partials/posts/:id
  const deleteMatch = pathname.match(/\/partials\/posts\/(\d+)/);
  if (deleteMatch && event.request.method === 'DELETE') {
    const id = parseInt(deleteMatch[1], 10);
    posts = posts.filter(p => p.id !== id);
    event.respondWith(
      new Response("", {
        status: 200,
        headers: { "Content-Type": "text/html; charset=utf-8" }
      })
    );
    return;
  }
});
