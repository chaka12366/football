// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('authForm');
    if (form) {
        form.addEventListener('submit', handleFormSubmit);
    }

    // Add input validation listeners
    const inputs = document.querySelectorAll('.form-control');
    inputs.forEach(input => {
        input.addEventListener('blur', validateInput);
        input.addEventListener('focus', function() {
            this.classList.remove('is-invalid');
        });
    });
});

/**
 * Validate individual input field
 */
function validateInput(e) {
    const input = e.target;
    const value = input.value.trim();
    let isValid = true;

    switch(input.name) {
        case 'email':
            isValid = value && isValidEmail(value);
            break;
        case 'password':
            isValid = value && value.length >= 6;
            break;
    }

    if (!isValid) {
        input.classList.add('is-invalid');
    } else {
        input.classList.remove('is-invalid');
    }
}

/**
 * Handle form submission
 */
function handleFormSubmit(e) {
    e.preventDefault();

    const email    = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value.trim();
    const submitBtn = document.getElementById('submitBtn');

    // Basic validation
    if (!email || !password) {
        showToast('Please fill in all required fields', 'error');
        return;
    }

    if (!isValidEmail(email)) {
        showToast('Please enter a valid email address', 'error');
        document.getElementById('email').classList.add('is-invalid');
        return;
    }

    // Disable button while processing
    submitBtn.disabled = true;
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'Processing...';

    // Prepare form data
    const formData = new FormData();
    formData.append('action', 'login');
    formData.append('email', email);
    formData.append('password', password);

    const rememberMe = document.getElementById('rememberMe').checked;
    formData.append('rememberMe', rememberMe ? '1' : '0');

    // Send request
    fetch('../../php/api/auth.php', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            showToast(data.message || 'An error occurred', 'error');
        } else {
            showToast(data.message, 'success');
            setTimeout(() => {
                if (data.redirect) {
                    window.location.href = data.redirect;
                }
            }, 1500);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showToast('Network error. Please try again.', 'error');
    })
    .finally(() => {
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
    });
}

/**
 * Validate email format
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/* =============================================================
   TOAST SYSTEM — Banner style, slides in from top
   ============================================================= */

// Inject keyframe animation once
(function injectToastStyles() {
    if (document.getElementById('toastStyles')) return;
    const style = document.createElement('style');
    style.id = 'toastStyles';
    style.textContent = `
        @keyframes toastSlideIn {
            from { transform: translateX(110%); opacity: 0; }
            to   { transform: translateX(0);    opacity: 1; }
        }
        @keyframes toastSlideOut {
            from { transform: translateX(0);    opacity: 1; }
            to   { transform: translateX(110%); opacity: 0; }
        }
        .toast-banner {
            animation: toastSlideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
        }
        .toast-banner.hide {
            animation: toastSlideOut 0.35s ease-in forwards;
        }
        .toast-progress {
            position: absolute;
            bottom: 0;
            left: 0;
            height: 3px;
            border-radius: 0 0 0 10px;
            animation: toastProgress linear forwards;
        }
        @keyframes toastProgress {
            from { width: 100%; }
            to   { width: 0%; }
        }
        .toast-close-btn:hover {
            opacity: 1 !important;
        }

        /* Mobile: smaller and tighter */
        @media (max-width: 480px) {
            #toastContainer {
                top: 10px !important;
                right: 10px !important;
                width: 220px !important;
            }
            .toast-banner {
                font-size: 0.72rem !important;
                padding: 8px 10px 12px 10px !important;
                border-radius: 7px !important;
            }
        }
    `;
    document.head.appendChild(style);
})();

// Ensure toast container exists (top-center)
function getToastContainer() {
    let container = document.getElementById('toastContainer');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toastContainer';
        container.style.cssText = `
            position: fixed;
            top: 16px;
            right: 16px;
            z-index: 9999;
            display: flex;
            flex-direction: column;
            gap: 8px;
            align-items: flex-end;
            pointer-events: none;
            width: 280px;
            box-sizing: border-box;
        `;
        document.body.appendChild(container);
    }
    return container;
}

/**
 * Show a banner toast notification
 * @param {string} message
 * @param {'success'|'error'|'info'} type
 * @param {number} duration  ms before auto-dismiss (default 4000)
 */
function showToast(message, type = 'info', duration = 4000) {
    const container = getToastContainer();

    const themes = {
        success: {
            bg:         '#388e3c',
            iconBg:     'rgba(0,0,0,0.15)',
            text:       '#ffffff',
            label:      'Success',
            icon:       '✓',
            progressBg: 'rgba(255,255,255,0.5)',
        },
        error: {
            bg:         '#c62828',
            iconBg:     'rgba(0,0,0,0.15)',
            text:       '#ffffff',
            label:      'Error',
            icon:       '!',
            progressBg: 'rgba(255,255,255,0.5)',
        },
        info: {
            bg:         '#1565c0',
            iconBg:     'rgba(0,0,0,0.15)',
            text:       '#ffffff',
            label:      'Info',
            icon:       'i',
            progressBg: 'rgba(255,255,255,0.5)',
        },
    };

    const t = themes[type] || themes.info;

    const toast = document.createElement('div');
    toast.className = 'toast-banner';
    toast.style.cssText = `
        position: relative;
        display: flex;
        align-items: flex-start;
        gap: 10px;
        background: ${t.bg};
        color: ${t.text};
        padding: 10px 12px 14px 12px;
        border-radius: 8px;
        font-family: 'Poppins', sans-serif;
        font-size: 0.78rem;
        box-shadow: 0 4px 16px rgba(0,0,0,0.22);
        pointer-events: all;
        width: 100%;
        box-sizing: border-box;
        overflow: hidden;
    `;

    toast.innerHTML = `
        <!-- Close button (left) -->
        <button class="toast-close-btn" style="
            flex-shrink: 0;
            background: none;
            border: none;
            color: ${t.text};
            font-size: 1rem;
            cursor: pointer;
            opacity: 0.6;
            padding: 0;
            margin-top: 1px;
            line-height: 1;
            transition: opacity 0.2s;
        ">✕</button>

        <!-- Text content -->
        <div style="flex: 1; min-width: 0;">
            <div style="font-weight: 700; font-size: 0.82rem; margin-bottom: 2px;">${t.label}</div>
            <div style="font-weight: 400; font-size: 0.76rem; opacity: 0.92; line-height: 1.4;">${message}</div>
        </div>

        <!-- Icon circle (right) -->
        <div style="
            flex-shrink: 0;
            width: 28px;
            height: 28px;
            border-radius: 50%;
            background: ${t.iconBg};
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.9rem;
            font-weight: 700;
            margin-top: 1px;
        ">${t.icon}</div>

        <!-- Progress bar -->
        <div class="toast-progress" style="
            background: ${t.progressBg};
            animation-duration: ${duration}ms;
        "></div>
    `;

    // Close button
    toast.querySelector('.toast-close-btn').addEventListener('click', () => dismissToast(toast));

    container.appendChild(toast);

    // Auto dismiss
    const timer = setTimeout(() => dismissToast(toast), duration);
    toast._timer = timer;
}

function dismissToast(toast) {
    if (toast._dismissed) return;
    toast._dismissed = true;
    clearTimeout(toast._timer);
    toast.classList.add('hide');
    setTimeout(() => toast.remove(), 380);
}