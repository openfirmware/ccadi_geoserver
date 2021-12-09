# Policies

Chef Infra uses Policy Files to lock a set of libraries together for a specific Chef Cookbook version. This versioning is separate from tags and branches used in git, and it is up to the developer to keep these synchronized.

The primary policy file is at the root of the repository at `Policyfile.rb`. This is the recommended production policy to use.

Alternative policies are kept in this directory for special cases and development.
