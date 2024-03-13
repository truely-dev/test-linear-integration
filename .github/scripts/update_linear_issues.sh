#!/bin/bash

STATE_ID="7db1c39e-bc7e-4c54-8ba9-eb0511002041"
 # Fetch the last 100 commits
git fetch --all
commits=$(git log release/dev -100 --pretty=format:'%H %s')

# Find 20 commits matching the pattern and extract issue ids
issue_ids=$(echo "$commits" | grep -E "^.*Merge pull request.*tes-[0-9]+-.*$" | sed -E 's/.*tes-([0-9]+)-.*/TES-\1/' | tr '[:lower:]' '[:upper:]' | head -20)

echo $issue_ids

# Initialize an empty array to track processed issue IDs
processed_issues=""

# Loop through each issue ID and update its status via the Linear API if not already processed
for issue_id in $issue_ids; do
    # Check if the issue has already been processed
    if [[ $processed_issues != *"$issue_id"* ]]; then
        echo "Updating issue $issue_id"
        
        payload="{\"query\":\"mutation { issueUpdate(id: \\\"$issue_id\\\", input: {stateId: \\\"$STATE_ID\\\"}) { success }}\"}"

        # Use curl to send the payload
        curl -X POST -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" --data "$payload" "https://api.linear.app/graphql"

        # Add the issue_id to the string of processed issues to avoid duplicates
        processed_issues="$processed_issues $issue_id"
    else
        echo "Skipping already processed issue $issue_id"
    fi
done
