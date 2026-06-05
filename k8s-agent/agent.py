import subprocess
import requests
import json

# ── Config ────────────────────────────────────────────
OLLAMA_URL = "http://192.168.1.11:11434/api/chat"
MODEL      = "qwen2.5:7b"

# ── Step 1: Run kubectl and collect evidence ───────────

def run_kubectl(args):
    """Run a kubectl command and return the output as a string."""
    result = subprocess.run(
        ["kubectl"] + args,
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        return f"ERROR: {result.stderr.strip()}"
    return result.stdout.strip()


def collect_evidence():
    """Gather cluster state — pods, events, logs from unhealthy pods."""
    print("\n🔍 Collecting cluster evidence...\n")

    # Get all pods across all namespaces
    print("  → Checking pods...")
    pods_json = run_kubectl(["get", "pods", "--all-namespaces", "-o", "json"])

    # Stop early if kubectl itself failed
    if pods_json.startswith("ERROR"):
        print(f"\n❌ kubectl failed: {pods_json}")
        print("   Check: is your cluster running?")
        print("   Run:   kubectl config current-context")
        print("   Run:   minikube status")
        return [], "", {}

    # Parse and find unhealthy pods
    unhealthy = []
    try:
        data = json.loads(pods_json)
        for pod in data["items"]:
            name      = pod["metadata"]["name"]
            namespace = pod["metadata"]["namespace"]
            phase     = pod["status"].get("phase", "Unknown")

            # Check container statuses for known failure reasons
            for cs in pod["status"].get("containerStatuses", []):
                state   = cs.get("state", {})
                waiting = state.get("waiting", {})
                reason  = waiting.get("reason", "")

                if reason in ["CrashLoopBackOff", "ImagePullBackOff",
                              "ErrImagePull", "OOMKilled", "Error",
                              "CreateContainerConfigError"]:
                    unhealthy.append({
                        "name":      name,
                        "namespace": namespace,
                        "reason":    reason,
                        "message":   waiting.get("message", "")
                    })

            # Catch pods stuck in Pending or Failed phase
            already_added = [u["name"] for u in unhealthy]
            if phase in ["Failed", "Pending"] and name not in already_added:
                unhealthy.append({
                    "name":      name,
                    "namespace": namespace,
                    "reason":    phase,
                    "message":   ""
                })

    except json.JSONDecodeError as e:
        print(f"  ❌ Failed to parse pod JSON: {e}")
        return [], "", {}

    # Get recent warning events
    print("  → Reading cluster events...")
    events = run_kubectl([
        "get", "events", "--all-namespaces",
        "--field-selector=type=Warning",
        "--sort-by=.lastTimestamp"
    ])

    # Get logs from unhealthy pods (limit to first 3)
    logs_collected = {}
    for pod in unhealthy[:3]:
        print(f"  → Reading logs from {pod['name']}...")

        # Try previous container first (the one that crashed)
        logs = run_kubectl([
            "logs", pod["name"],
            "-n", pod["namespace"],
            "--tail=50",
            "--previous"
        ])

        # Fall back to current container if no previous exists
        if "ERROR" in logs or "found no previous terminated container" in logs:
            logs = run_kubectl([
                "logs", pod["name"],
                "-n", pod["namespace"],
                "--tail=50"
            ])

        logs_collected[pod["name"]] = logs

    return unhealthy, events, logs_collected


# ── Step 2: Format evidence into a prompt ─────────────

def build_prompt(unhealthy, events, logs):
    """Turn raw kubectl output into a focused prompt for the LLM."""

    # Format unhealthy pod list
    pod_section = "UNHEALTHY PODS:\n"
    for pod in unhealthy:
        pod_section += f"  - {pod['namespace']}/{pod['name']}: {pod['reason']}"
        if pod["message"]:
            pod_section += f"\n    Message: {pod['message']}"
        pod_section += "\n"

    # Format logs section
    log_section = "CONTAINER LOGS (last 50 lines from unhealthy pods):\n"
    if logs:
        for pod_name, log_content in logs.items():
            log_section += f"\n--- {pod_name} ---\n"
            # Truncate very long logs to keep prompt size manageable
            if len(log_content) > 2000:
                log_content = "...(truncated)...\n" + log_content[-2000:]
            log_section += log_content + "\n"
    else:
        log_section += "  No logs available.\n"

    # Format events (last 30 lines only)
    event_lines = events.strip().split("\n")[-30:]
    event_section = "RECENT WARNING EVENTS:\n" + "\n".join(event_lines)

    prompt = f"""You are a Kubernetes troubleshooting expert.

Analyze the following cluster state and provide a diagnosis.

{pod_section}
{log_section}
{event_section}

Respond in this exact format:

ROOT CAUSE:
(one clear sentence explaining what is wrong)

EXPLANATION:
(2-3 sentences with more detail about why this is happening)

SUGGESTED FIX:
(the exact kubectl command or config change needed to resolve this)
"""
    return prompt


# ── Step 3: Call Qwen via Ollama ───────────────────────

def ask_qwen(prompt):
    """Send the prompt to Qwen and return the response."""
    print("\n🤖 Sending evidence to Qwen for analysis...")
    print("   (this takes 15-30 seconds on a 7B model)\n")

    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model":    MODEL,
                "messages": [
                    {
                        "role":    "system",
                        "content": (
                            "You are a senior Kubernetes engineer with 10 years of experience. "
                            "You diagnose cluster problems clearly and concisely. "
                            "You always suggest a specific, actionable fix. "
                            "You never say 'I need more information' — you work with what you have."
                        )
                    },
                    {
                        "role":    "user",
                        "content": prompt
                    }
                ],
                "stream": False
            },
            timeout=120
        )
        response.raise_for_status()
        return response.json()["message"]["content"]

    except requests.exceptions.ConnectionError:
        return "❌ Cannot reach Ollama. Is it running on your Mac? Run: OLLAMA_HOST=0.0.0.0 ollama serve"
    except requests.exceptions.Timeout:
        return "❌ Qwen took too long to respond. The model may be overloaded."


# ── Main ───────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  Kubernetes AI Troubleshooting Agent")
    print("  Model: qwen2.5:7b via Ollama")
    print("  Cluster:", run_kubectl(["config", "current-context"]))
    print("=" * 60)

    # Collect evidence from the cluster
    unhealthy, events, logs = collect_evidence()

    if not unhealthy:
        print("\n✅ Cluster looks healthy — no unhealthy pods found.\n")
        return

    print(f"\n⚠️  Found {len(unhealthy)} unhealthy pod(s):")
    for pod in unhealthy:
        print(f"   - {pod['namespace']}/{pod['name']}: {pod['reason']}")

    # Build the prompt
    prompt = build_prompt(unhealthy, events, logs)

    # Get diagnosis from Qwen
    diagnosis = ask_qwen(prompt)

    # Print the result
    print("=" * 60)
    print("  DIAGNOSIS")
    print("=" * 60)
    print(diagnosis)
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()