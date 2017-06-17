# A quick outline of what must be done to get gpg & git working.

1. Configure git to automatically gpgsign commits. This consists of
   pointing git to your signing key ID, and then enabling commit
   automatic signing.
```sh
git config --global user.signingkey <YOUR-SIGNING-KEY-PUB-ID>
git config --global commit.gpgsign true
```

Don't forget to upload your public key to Github!
https://github.com/blog/2144-gpg-signature-verification
Note: There needs to be a three-way match on your email for Github to show
the commit as 'verified': The commit email, github email, & the email associated with the public key

Learn about creating a GPG key and the knowledge behind these commands here:
https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work
