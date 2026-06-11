import argparse
import logging
import os
from datetime import datetime, timezone
from typing import Any, Dict

import requests


def format_duration(seconds: float) -> str:
    """Format duration into human-readable string."""

    seconds = float(seconds)
    if seconds < 0:
        return "0s"
    elif seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        return f"{seconds / 60:.1f}min"
    elif seconds < 86400:
        return f"{seconds / 3600:.1f}h"
    else:
        return f"{seconds / 86400:.1f}d"


def build_slack_payload(exit_code: int, duration_seconds: float) -> Dict[str, Any]:
    """Build Slack message payload."""

    job_message = "✅ Experiment completed" if exit_code == 0 else "❌ Experiment failed to complete"

    return {
        "blocks": [
            {"type": "section", "text": {"type": "mrkdwn", "text": job_message}},
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Experiment Batch:*\n{os.getenv('MLFLOW_EXPERIMENT_NAME', 'N/A')}"},
                    {"type": "mrkdwn", "text": f"*Experiment Name:*\n{os.getenv('MLFLOW_JOB_NAME', 'N/A')}"},
                    {"type": "mrkdwn", "text": f"*Actor:*\n{os.getenv('GITHUB_ACTOR', 'Unknown')}"},
                    {"type": "mrkdwn", "text": f"*Duration:*\n{format_duration(duration_seconds)}"},
                ],
            },
        ]
    }


def main() -> None:
    """Main function to send Slack notification for experiment results."""

    parser = argparse.ArgumentParser(description="Send Slack notification for experiment results")
    parser.add_argument("--exit-code", type=int, required=True, help="Job exit code")
    parser.add_argument("--start-time", type=int, required=True, help="Job start time (Unix timestamp)")
    args = parser.parse_args()

    webhook_url = os.getenv("WEBHOOK_URL")
    if not webhook_url:
        raise ValueError("Required environment variable WEBHOOK_URL is not set")

    current_time = int(datetime.now(timezone.utc).timestamp())
    duration_seconds = current_time - args.start_time
    if duration_seconds < 0:
        logging.warning("Duration is negative, start time might be later than current time")

    try:
        logging.info("Building Slack payload...")
        payload = build_slack_payload(args.exit_code, duration_seconds)

        logging.info("Sending Slack notification to webhook...")
        response = requests.post(url=webhook_url, json=payload, timeout=30)
        response.raise_for_status()

        logging.info("Slack notification sent successfully")
    except requests.exceptions.RequestException as e:
        logging.error(f"Network request failed: {e}")
    except Exception as e:
        logging.error(f"Unexpected error occurred: {e}")


if __name__ == "__main__":
    main()
