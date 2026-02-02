{
  local k = import 'k.libsonnet',
  local secret = k.core.v1.secret,

  local this = self,

  newSimpleCert(secretName, issuerName, cn, dnsNames=[]): {
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: secretName,
      },
      spec: {
        secretName: secretName,
        commonName: cn,
        dnsNames: [cn] + dnsNames,
        usages: [
          'server auth',
          // 'client auth' ??
        ],
        duration: '720h',  // 30 days
        privateKey: {
          algorithm: 'ECDSA',
        },
        renewBefore: '504h',  // 21 days
        issuerRef: {
          name: issuerName,
          kind: 'ClusterIssuer',
          group: 'cert-manager.io',
        },
      },
    },
  },

  newPublicCert(secretName, issuerName, cn, dnsNames=[]): {
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: secretName,
      },
      spec: {
        secretName: secretName,
        commonName: cn,
        dnsNames: [cn] + dnsNames,
        usages: ['server auth'],
        // duration: '300h',
        // privateKey: {
        //   algorithm: 'ECDSA',
        // },
        renewBefore: '720h',
        issuerRef: {
          name: issuerName,
          kind: 'ClusterIssuer',
          group: 'cert-manager.io',
        },
      },
    },
  },

  newVaultIssuer(server, path, caBundle, tokenSecretRefName='cert-manager-vault-token'): {
    vault_issuer: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'ClusterIssuer',
      metadata: {
        name: 'vault-issuer',
      },
      spec: {
        vault: {
          path: path,
          server: server,
          caBundle: caBundle,
          auth: {
            tokenSecretRef: {
              name: tokenSecretRefName,
              key: 'VAULT_TOKEN',
            },
          },
        },
      },
    },
  },

  newAcmeIssuer(contact, dnsZones=[], acmedns=''): {
    local secretName = 'acme-dns',

    acme_account_secret:
      secret.new(secretName, { 'acmedns.json': std.base64(acmedns) }),

    acme_issuer: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'ClusterIssuer',
      metadata: {
        // name: 'letsencrypt-staging',
        name: 'letsencrypt',
      },
      spec: {
        acme: {
          // You must replace this email address with your own.
          // Let's Encrypt will use this to contact you about expiring
          // certificates, and issues related to your account.
          email: contact,
          // server: 'https://acme-staging-v02.api.letsencrypt.org/directory',
          server: 'https://acme-v02.api.letsencrypt.org/directory',
          privateKeySecretRef: {
            // Secret resource that will be used to store the account's private key.
            name: 'acme-account-key',
          },
          // Add a single challenge solver, HTTP01 using nginx
          solvers: [
            {
              selector: {
                dnsZones: dnsZones,
              },
              dns01: {
                acmeDNS: {
                  host: 'https://auth.acme-dns.io',
                  accountSecretRef: {
                    name: 'acme-dns',
                    key: 'acmedns.json',
                  },
                },
              },
            },
          ],
        },
      },
    },
  },
}
