#!/bin/bash
# AWS IAM Manager - CloudOps Solutions
# Version: 1.0
# Description: Creates IAM users, admin group, and assigns permissions

# --------------------------
# CONFIGURATION
# --------------------------
IAM_USERS=("devops_kurunmi" "devops_kako" "devops_eniobanke" "devops_gbola" "devops_adiamoh")
IAM_GROUP="admin"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
LOG_FILE="iam_setup_$(date +%Y%m%d_%H%M%S).log"

# ---------------------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------------------

# Initialize logging
init_logging() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "================ AWS IAM Setup Started at $(date) ======================"
}

# Verify AWS CLI configuration

verify_aws_cli() {
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "ERROR: AWS CLI not configured or lacks permissions" | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "AWS CLI configured properly and good to go"
}

# Create IAM users
create_users() {
    echo "Creating IAM users..."
    for user in "${IAM_USERS[@]}"; do
        if aws iam create-user --user-name "$user" >/dev/null 2>&1; then
            echo " Created user : $user"
        else
            echo "⚠ Failed to create user: $user (may already exist)"
        fi
    done
}

# Create admin group
create_group() {
    echo "Creating IAM group '$IAM_GROUP'..."
    if aws iam create-group --group-name "$IAM_GROUP" >/dev/null 2>&1; then
        echo " Created group: $IAM_GROUP"
    else
        echo " Failed to create group (may already exist)"
    fi
}

# Attach admin policy to group
attach_policy() {
    echo "Attaching policy '$POLICY_ARN' to '$IAM_GROUP'..."
    if aws iam attach-group-policy --group-name "$IAM_GROUP" --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
        echo "Attached policy"
    else
        echo "Failed to attach policy (may already be attached)"
    fi
}

# Add users to admin group
add_users_to_group() {
    echo "Adding users to '$IAM_GROUP'..."
    for user in "${IAM_USERS[@]}"; do
        if aws iam add-user-to-group --group-name "$IAM_GROUP" --user-name "$user" >/dev/null 2>&1; then
            echo "Added $user to $IAM_GROUP"
        else
            echo "Failed to add $user (may already be in group)"
        fi
    done
}

# Verify setup
verify_setup() {
    echo "Verifying setup..."
    echo "Users created:"
    aws iam list-users --query "Users[?contains(UserName, 'devops_user')].UserName" --output table
    
    echo "Group memberships:"
    for user in "${IAM_USERS[@]}"; do
        aws iam list-groups-for-user --user-name "$user" --query "Groups[].GroupName" --output table
    done
}

# ------------------------------------------------------------------------
# MAIN EXECUTION
# ------------------------------------------------------------------------
# below function is the main function that runs all other function the script for better organisatio of the script.
main() {
    init_logging
    verify_aws_cli
    create_users
    create_group
    attach_policy
    add_users_to_group
    verify_setup
    echo "========== Setup completed. Log saved to $LOG_FILE ============"
}

main
