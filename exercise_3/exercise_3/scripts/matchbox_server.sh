#!/usr/bin/env bash

set -eu
source /etc/environment

DEBIAN_FRONTEND=noninteractive apt-get -qq update

# TODO as for loop
if ! [[ -e /usr/bin/curl ]];
then
  echo "Install curl"
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -y curl vim
fi

## Move stuff into place
if ! [[ -e /usr/local/bin/matchbox ]];
then
  echo "Configure Machbox"
  ## Download matchbox and signing key
  MATCHBOX_URL=https://github.com/coreos/matchbox/releases/download/${MATCHBOX_VERSION}/matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz
  curl -sLO ${MATCHBOX_URL}
  curl -sLO ${MATCHBOX_URL}.asc
  ## Verify download
  #if ! gpg --list-keys 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E >/dev/null; then
  #  gpg --keyserver pgp.mit.edu --recv-key 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E
  #fi
  #gpg --verify $(basename ${MATCHBOX_URL}.asc) $(basename $MATCHBOX_URL)
  ## Extract stuff
  tar -xzf $(basename $MATCHBOX_URL)
  rm -rf  $(basename $MATCHBOX_URL)
  cp matchbox-${MATCHBOX_VERSION}-linux-amd64/matchbox /usr/local/bin
  cat <<EOF >/etc/systemd/system/matchbox.service
[Unit]
Description=CoreOS matchbox Server
Documentation=https://github.com/coreos/matchbox

[Service]
User=matchbox
Group=matchbox
Environment="MATCHBOX_ADDRESS=0.0.0.0:8080"
Environment="MATCHBOX_RPC_ADDRESS=0.0.0.0:8081"
ExecStart=/usr/local/bin/matchbox

# systemd.exec
ProtectHome=yes
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  useradd -U matchbox
  mkdir -p /var/lib/matchbox/assets
  mkdir -p /var/lib/matchbox/assets/zeus
  chown -R matchbox:matchbox /var/lib/matchbox
  curl -sLO https://raw.githubusercontent.com/coreos/matchbox/948bdee1658757413726ab8dcdb8e5e18e59bee5/scripts/get-coreos
  chmod +x ./get-coreos
  ./get-coreos stable ${CL_VERSION} "/var/lib/matchbox/assets"
fi

if ! [[ -e /etc/matchbox ]]; then
  #export SAN=DNS.1:matchbox.example.com,IP.1:$(ip -4 a s dev eth0|grep inet|awk '{ print $2 }'|cut -d'/' -f1),IP.2:$(ip -4 a s dev eth1|grep inet|awk '{ print $2 }'|cut -d'/' -f1)
  #cd ./matchbox-${MATCHBOX_VERSION}-linux-amd64/scripts/tls
  ## Can be used to generate a ca and certificates, but we want this to be static for testing
  ## so the user doesn't always have to replace the client certs
  #./cert-gen
  mkdir -p /etc/matchbox
  cat <<EOF >/etc/matchbox/ca.crt
-----BEGIN CERTIFICATE-----
MIIFDTCCAvWgAwIBAgIJAP5mazsrqhqaMA0GCSqGSIb3DQEBCwUAMBIxEDAOBgNV
BAMMB2Zha2UtY2EwHhcNMTcwNjIwMDkzOTEzWhcNMjcwNjE4MDkzOTEzWjASMRAw
DgYDVQQDDAdmYWtlLWNhMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
sNe56zQbiVqUHlnR7fEp+m28F3BN0cB/F4XyY2C5Yrx859t/yEJzTKuz8E4k6+aV
zmXOKnI9PN9czx7KUNMDoPeQOsYVq+UWiyJ7Di2me2WZuHsClMXcoPck5cJLlOsD
/irL8rrQiX8dP+4I64ATl5K7AVEL4kzcQfbXa/qiCxBf3Q+7TH7NdA529Wq1a76W
ZzLfHvdr7ZQ7ICURN4eEdeBsKV372WpwPdWsKFajgdca1v2Rd11G6pBKYUBFBI5k
rGVWbQ9Q8joN5l45Qh+1PTXDpBChDx495tL0g8znMG/UVvoSEBVQUI9n3jvvZK88
9pK5ngMnUvMP0cWjpo5/E/MO90K2H0FnInVhKjsnxUN7su3wgTkZBxYVqr6iuaXC
Z5+lFhC6yYgh/PtSaHMoRATdUs2Zd8BtPK3GKSjGIlJ6GnIX7/KrRJ1JUUTXZUdQ
CGQggjMuarQVsqMVBuKHJ8OQXspFoMF5dshAaNshgyliI+masxUNeZfVRwRMv4gc
IUnMjqwP99lFCDYUiItSRjcDuuYnlP6cF6DH0akIBTKHqHTNKrfUjMY6rq6i6R+4
7k6tfnGCbQvo0l9C3avuCh+UmoGKEa0TFrRZ0ptb//ROTkXzwVPMhvXbIgPytkZe
JRbqjQ6PrefXc05MW9aw1I9YXk/UYW86Q9963Tfg2u8CAwEAAaNmMGQwHQYDVR0O
BBYEFDZdrY9H339AK11GZIl4WK9EKWlKMB8GA1UdIwQYMBaAFDZdrY9H339AK11G
ZIl4WK9EKWlKMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMA0G
CSqGSIb3DQEBCwUAA4ICAQAQ07TB6Ne2wgMq+BcEws7hxZlRkmNfRmUcoAsgpxlh
s/CUQqx7rHrVwo3NPL4taLYQL9+EqI0HqOQOQT75xgJ+Yvj0JE9r4BT4iaiaRIlg
FTDjSB9mf3Xps7khiFNpR31fSd7XykiRsA09aGcvUrIsyizJQrZ3mtbAV2t5KCvW
lf9PtNOJTGKMWi1+tfRYrAPW1PZl47Eo1/AMbrSqab61BNyNQ0odfc4+4cWNxCyp
vnok4rcTQiF3gjbuqM2VQ7uZZxy15koZMp0C0EE9gg2UT7BdB7PCuEoByzlAd+zZ
DoGCDFRuCqDAq4k0uCavESGXH1pyPqb78ouVveYpa3+CUKYqf+qWMDHDRKuQF++V
E6Svi3jKV7kwqSm4W8MPj3/4H3+GV9IGyiQc1aapg9sbz2336r9fBeghuSDu71Da
Kxrw/HRb1tywfByJ+fcHJfl7YFGp8JKZoXdJknWp2zo01kaaPTi0hiurwww7j4Z6
d1RrqWkNXznLrG0qU/RkYEZyMpsEdnq/1f92WUKKANPb/FnhEKrn3orFvue8pSxL
cDYcYVrXdzP7PMmSkNEI9bEzIJFccCBmAGyvoPtdnuVSZzJrjfVGXoqOgzabCtfm
uy2v5Idy2LGm2FbLghLaScFzL4kAn29t7IucvMJz4L7Zs6Pk0l8R8OBajwkfGn8Z
NQ==
-----END CERTIFICATE-----
EOF
  cat <<EOF >/etc/matchbox/ca.key
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
EOF
  cat <<EOF >/etc/matchbox/client.crt
-----BEGIN CERTIFICATE-----
MIIEYDCCAkigAwIBAgICEAEwDQYJKoZIhvcNAQELBQAwEjEQMA4GA1UEAwwHZmFr
ZS1jYTAeFw0xNzA2MjAwOTM5MTNaFw0xODA2MjAwOTM5MTNaMBYxFDASBgNVBAMM
C2Zha2UtY2xpZW50MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyNel
dQxc9psZNFaf6gNzOLWGGtFURlMFWsoczGkfZVoX7wj3JAu3HojUeyNgOlK0RyEj
2wiMHjnRqronj/5XQ7o/z7NNTArkqUIbEntCPYPn74qrLrakL+xFJ5s310ZB6wlY
AG6r/fU+548dbbiutTO4wKw6ZqrijIWDTAUucMway7Eh58vbwEuICcefB22roFqp
RYY+HaDR7GOFt+ksFKkrfiYCHcAFeL4yzvVJnct6QZBRhopR4UA3sMj6B8nfHp1R
fgXrZy0cjHuIrtq/2DFg3vPnCf/yVI5ZKfAxUecbWYcVm6HTymPjUYiOFWfVPA+u
X1hikCeibFyuHY9iJQIDAQABo4G7MIG4MAkGA1UdEwQCMAAwEQYJYIZIAYb4QgEB
BAQDAgeAMDMGCWCGSAGG+EIBDQQmFiRPcGVuU1NMIEdlbmVyYXRlZCBDbGllbnQg
Q2VydGlmaWNhdGUwHQYDVR0OBBYEFE29mNna9Svelk8sgqTVrA0jaEUxMB8GA1Ud
IwQYMBaAFDZdrY9H339AK11GZIl4WK9EKWlKMA4GA1UdDwEB/wQEAwIF4DATBgNV
HSUEDDAKBggrBgEFBQcDAjANBgkqhkiG9w0BAQsFAAOCAgEAfPreqUmDuM3YHtaV
ZVt2+y3cQd/l6i07CHn0KCDv2ltexBcyVrMA6ztx4E3KwXx+K6mCHQtHjzdLw5Am
sgaCwINEfuns/UHxk3oGvGHT8+GsN7NM5zifRt2NnaCDWkB2XZ3Uh2Dpyxuq9/PL
aoIZk/7WDQ/bQQfcbBRCMGqcNI0ioFR00xBrzaRLc/cr6XHbPnajOmpZJ4g2nuwc
2C50oEHZ5ZDeM3TKLGvR4LPAAo248C/7bVCJpy6LHxOFQ2nw9BOXEoVWGVDrkNlo
iOs9gHuwuKfMnGhSOnHqcTGysHXRDlkCTRpEoGnvEXADOT8cNbfY1YcZdTMV8yKy
v7Dtpb+vKD7WbZnufscn6JXTfr7V/kjdSnKOHdMmtXHfZosNvQUVa0TYzE+dzt58
22vFPp8vTum2IZ+6ayTBcdpts4u0Sf5/LVJqu+Me8ZfUdGdIxvRdymvZZgLKJeWs
atWRTtldUeqZSLw7GD50c5hGGlsGQwP1IFKYp+in9EuoR86t0lp4Ts464Tm+0mK6
WfJceYStR06qFCk2Ir6bWx4jpoB2nnseavs1BX2lrZhr3K6H+4BarXHsKZ3mfBZ7
+giSkCKpMGJ+ZOAMlstualAOYcaeocHn+M1J5+0bKPeZOzoNPJmHjRD7J2RFOVAx
J6vL1P6+/jbVLSzZfyWcFX+XZ6w=
-----END CERTIFICATE-----
EOF
  cat <<EOF >/etc/matchbox/client.key
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyNeldQxc9psZNFaf6gNzOLWGGtFURlMFWsoczGkfZVoX7wj3
JAu3HojUeyNgOlK0RyEj2wiMHjnRqronj/5XQ7o/z7NNTArkqUIbEntCPYPn74qr
LrakL+xFJ5s310ZB6wlYAG6r/fU+548dbbiutTO4wKw6ZqrijIWDTAUucMway7Eh
58vbwEuICcefB22roFqpRYY+HaDR7GOFt+ksFKkrfiYCHcAFeL4yzvVJnct6QZBR
hopR4UA3sMj6B8nfHp1RfgXrZy0cjHuIrtq/2DFg3vPnCf/yVI5ZKfAxUecbWYcV
m6HTymPjUYiOFWfVPA+uX1hikCeibFyuHY9iJQIDAQABAoIBAFB7ScxLtf0ETedR
RyepVkTFSQX6GEFOB3lIQJ4RCgm9PpYFC7QgFbNgtXTayjbU6XUPbKTbGfsKxGAb
1Lq4+xMi0WtTuIfeXZ8N5HdVeUfZUdoFwW8otUaW8WdbpdbYSpX62o7hyn4sBpcY
HHzZYvktzr02xvhZRgt1fRW7hc6g5eTxNlhibxW8guFZ+gX+w3Sen5lLhwKOyKPS
u6US0pB+yQFThvleGT/YVsh9TSkHmUvZejyYYIE8Esd/E7sdG18pVt8YQq4kI9Vx
rr+s9v3LRlwIhsf67mvE9aYHyIPIoiy9VOAB46zsY6KGgTDLVHV8vhlcDa2qK4mJ
aOqyRwkCgYEA5dbE1DWXfK0qP1wiIzcawqVJd94W9YtAfH1qN0/vEIO4uVsPGG/+
bJXbEBLSNxZ4V9bQsVoN6cHJ2C5XkTefJmFhoWiXUs9dVIq+M8+iAFoFxvBe2xRj
HnJJ1Fh0Iw1t11EL8uYBD0zxvUS16ZzLufL4ngQljGXYh7+QKZKVmusCgYEA37Pz
vQV2uI8bqb/d3yo2KLf7LhctxkK83mzG5SthG5eh9d6Tbgv9HK3D27QVmqo3BKv0
YW93vIsw2cqtMPSnqnI0yTWqyC2wD9BmecOtRKle2rkxpiCuhqdqbKc+HLLZFpgr
k6fHS1+2zr0fV4chDloPLA8Q2F78/tZ4x1Wpky8CgYEAkk1My1w1yqoby2slW882
3JIEGyYm7TQv306h7wWVwqhmTK63BDI9/PbDFA82+tP11Mwr2cjeNF8j0dVl7k0+
pFq2n90I/jB7U1Zhzm8ryxeCt+jIKKJombfcYSvQ+YMR2U6A0aQxJoEvG/CB72vc
jsgoE8XF9QHbfEWnSZ9CVfMCgYEAv4gjuENlUr+0v7I3FUve8x4TQXM3Dfk2HHqm
ELEDg8xgL1NSh3ZcUKG2f/XASZxTXvybUJFPw26pdM/DWZcftx/xchUxFBOKGwAj
vT18rL0XKc5GZCa3RzMwO7c1xvyaQm4nYVTVngNlUb07iIV6F/+j3eVIVvl9Q/P9
lS4S8qECgYBD66QQZk3NLibxkvNZSHnQIPBr91CgFtAriiSv3ltHmP5R3sgjxL/h
U8kmsqG+FPrV8Cr2QQomByW8QxYHTgVlwZ/EsH2dB42IZw6pCQCjqp4FJ1zF8iCI
HkmEJz0CvY8nEq+Dhr0nQcUCmSKYe3p6brKGBZOtg+gwjhdRna0ZPA==
-----END RSA PRIVATE KEY-----
EOF
  cat <<EOF >/etc/matchbox/server.crt
-----BEGIN CERTIFICATE-----
MIIEsjCCApqgAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwEjEQMA4GA1UEAwwHZmFr
ZS1jYTAeFw0xNzA2MjAwOTM5MTNaFw0xODA2MjAwOTM5MTNaMBYxFDASBgNVBAMM
C2Zha2Utc2VydmVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4a/a
G7dG7ulfGSmnfFzYcXPbXnrUekZgHRP7nr83fTcsLRKeDa4CMwW8Ka7rri3AXEal
+6opffj3mREDuWvcZdJD0hRAYFfVwl7YC95jM6XTiywdEOTlurhtQVhPp2wY6k7W
tuvwroYegLUW7c/IoyJyLWHhXfPrix1Gs3Y4Erv5WECz4x936pmFHc/B1b4v4VYQ
BsovCA1XAuJ5aSKFuA/VtgvfSgxBA6hsjARqSTkH+RBwacWcHs8mDu83paqKt5GN
fvAGbnyewzLZGJ8M0kmnfySzFLr0W0UnocaQ7x1vboHrEAQZLXPmZh9H+XjXMX23
m73IX/ukMGNGT2kjWQIDAQABo4IBDDCCAQgwCQYDVR0TBAIwADARBglghkgBhvhC
AQEEBAMCBkAwMwYJYIZIAYb4QgENBCYWJE9wZW5TU0wgR2VuZXJhdGVkIFNlcnZl
ciBDZXJ0aWZpY2F0ZTAdBgNVHQ4EFgQULUwrbIqwS5fBXnrlBIy/dHhanZ4wQgYD
VR0jBDswOYAUNl2tj0fff0ArXUZkiXhYr0QpaUqhFqQUMBIxEDAOBgNVBAMMB2Zh
a2UtY2GCCQD+Zms7K6oamjAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYB
BQUHAwEwKwYDVR0RBCQwIoIUbWF0Y2hib3guZXhhbXBsZS5jb22HBMCoeW2HBMCo
AP4wDQYJKoZIhvcNAQELBQADggIBAF4OQXhQtnKulBQrgV8oS2mlMbR6HIUydV6U
zzgiSfSomAYIsGhhb2BkeZCRrD4SYDQMNcdPIiaQKecAJ3x6kXvE421jqjPb/j4i
9Sov0vdAQjbT1scNpfRlMELD0fX2wP9y2JbzAHJyXieAyCSLYBRrHsoPvbsizo8l
o5c4493VpbIWX5BegD8ww+sg3gtGWjmnSIcCnqr4gMw3FgQv+w8HkTJOzwqfsIlV
fv94Qql4kGmThqa9Ue8+Zciybsbzq8oPKpTioP4TRXjdgvYZ3qreQJuytmkNdd4u
FMTEyHFoCzKs+q+vTeDdUqyvWgHdATR6N9l01tcjGHj++RmsEgogGiygXeliEhEx
6cCw/ZqtO9y+YDbfjjIDZ78VVyWUI0qT/P3Dit3uXtyMrHBkBjrcmCt/JGcf1n84
W4hDvIYr+wRsUJuqw3UyslmKc885RG/PxvwL3Kvm9ZcR/y1j+VXV7NrRipiErxKv
ppXk154/BtqTltJnI3eLMHLMavle4YEw7XrymnMNL9swPcgjMm4qjebtQL6C8oS1
5Zcy873F19cpL9WVRV5sLxluy6JyWgw+zKRmfT01xnnnMnhaD0qEIu8uVIKde19E
nz70RPdAy3GLwBo3XFUaQBSIooGPH+O+rJk2iEb/oXCVZYpKyclUCMe7QoBc9Lkc
GIND+eKk
-----END CERTIFICATE-----
EOF
  cat <<EOF >/etc/matchbox/server.key
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA4a/aG7dG7ulfGSmnfFzYcXPbXnrUekZgHRP7nr83fTcsLRKe
Da4CMwW8Ka7rri3AXEal+6opffj3mREDuWvcZdJD0hRAYFfVwl7YC95jM6XTiywd
EOTlurhtQVhPp2wY6k7WtuvwroYegLUW7c/IoyJyLWHhXfPrix1Gs3Y4Erv5WECz
4x936pmFHc/B1b4v4VYQBsovCA1XAuJ5aSKFuA/VtgvfSgxBA6hsjARqSTkH+RBw
acWcHs8mDu83paqKt5GNfvAGbnyewzLZGJ8M0kmnfySzFLr0W0UnocaQ7x1vboHr
EAQZLXPmZh9H+XjXMX23m73IX/ukMGNGT2kjWQIDAQABAoIBAAZ09IWEedgN/zWG
Fo+dTGf6i5UpaHjTGJ7cWn+RMvI3KOFlPfZgOxngmSCMK5wBHRbGwqrvlF5RSCwt
63BboKOdH2mcQLdA7BGyivXT9/ybSvEZYv9/vP7Zle6fqy+8DP5vIP98wpcLqUW/
aJeHMVNRgfjAayU3/E4vmT07LaGDh3412ztI2ryeLvI2Z6QY/0w0qnCajSAQt0pi
V0SA2eHltkfxlS0Jb6vMHHMC2Rzwxz3iVf9XAJ4Gk4uCKnQzIUUHfu3Ij5imDsbj
lOkDMFx8i0SFCKz96LC/iGSynJt2KLgfYuQn15tZo7CLRXOPpZFlYYo9XwHs5ZIW
xtsDIDECgYEA9JDnU8Oia4YYxPummx2dyCcYxFk/0RD8HEYT5t5CzDWzk2VGUsWL
5UPoP3+BsiFtdp22FaJEUjE5YTJSB/d6QtISViq/s//SZPTsuAqcJ/RnSM9HMzDB
GcEvpEfOeTxGbVDrXPNM1wZGTSN1QIFcWg33dh/qGwCcdKmrXal9HcUCgYEA7Dz+
P1X0GkEm1abSvuKjSWOuqqsViBHZeaps3LOLblBO2rvVGO0AmmLNHOvWq5+MvNIO
3isspNr9dNd3GT0yINOBrfAt8veEwe/P6y3yUowdHN6EuennVCnSup2wXvWAAwhp
OWM0FRIeTS+w/jUyUQhcfD6sDH7skQNTbYYcvIUCgYBHKBHmMTmEh1OVnJJw90D9
B0MRfdYvgf2YTFtmBKzytX02GXVIh+mYHxXnw7V8mnU62dAsozW1pFTJjtaHMt4D
qxNitrVoLbqNXSWytoOQrG+Qo55XqovEbozqA2pzo7HqBG02ciOdPFof/30R85Fn
MkEZwVdf2+Gpn+QYMEQS8QKBgEVRSFERSYUCpQB/6Mq1+a+pHjFZ7gF1K1j11ueT
j1AZJGouP0MHF+w1HXZlBSJquIMXJ+GszXa6AzDroDi5qiHTrfN5zCHE2yGE2n9p
hfcOweQcrtlWdthNRVYYuw3B/4PkTevW3gtou5dubQLKXS9Fws16HkW0YHnUfgBf
H8N5AoGAdb4QuIzFUIy2THpleO8399G4MNd29qFieAb+Ys1N3yfHSlq5rZmXtHnn
bS6aqzmAq5/G5NvKhjvaYs8I0WQ922z4lQdUC2da7j8IxSvS0JLs7ZSFO1s4sHH4
wbScg2chhFDLT+DLFJWsN7vfefN7NY4C/CqfGd4vXadiEf0Bmns=
-----END RSA PRIVATE KEY-----
EOF
  # Enable and start matchbox service
  systemctl enable matchbox
  systemctl start matchbox
fi

# Download tftboot files
if ! [[ -e /var/lib/tftpboot ]]; then
   mkdir /var/lib/tftpboot
   curl -s -o /var/lib/tftpboot/ipxe.pxe https://boot.ipxe.org/ipxe.pxe
fi

# Install and configure isc dhcp
if ! [[ -e /etc/dhcp/dhcpd.conf ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -y isc-dhcp-server
  systemctl enable isc-dhcp-server.service
  
  sed -i 's/^INTERFACES=.*$/INTERFACES="eth2"/' /etc/default/isc-dhcp-server
 # Deploy hdd boot ipxe
 cat <<EOF >/var/lib/matchbox/assets/hdd.ipxe
#!ipxe
sanboot --no-describe --drive 0x80
EOF
fi
# Install and configure dnsmasq
# we can not use the builtin service name, as there is a systemd generator configured for it
if ! [[ -e /etc/systemd/system/dnsmasq-coreos.service ]]; then
   systemctl mask dnsmasq
   apt-get install -y dnsmasq
   cat <<EOF > /etc/systemd/system/dnsmasq-coreos.service
[Service]
ExecStart=/usr/sbin/dnsmasq \
  -d \
  --all-servers \
  --enable-tftp \
  --log-queries \
  --interface=eth1,eth2,eth3,eth4 \
  --except-interface=eth0,docker0,lo \
  --tftp-root=/var/lib/tftpboot \
  --address=/matchbox.example.com/192.168.0.254 \
  --address=/kmaster-fluffy-unicorn-az01-001/192.168.1.2 \
  --address=/kmaster-fluffy-unicorn-az01-001.unicorn.k8s.zone/192.168.1.2 \
  --address=/kworker-fluffy-unicorn-az01-001/192.168.1.3 \
  --address=/kworker-fluffy-unicorn-az01-001.unicorn.k8s.zone/192.168.1.3
[Install]
WantedBy=multi-user.target
EOF
   systemctl daemon-reload
   systemctl enable dnsmasq-coreos
   systemctl restart dnsmasq-coreos
fi

# TODO automate this step!
echo 1 > /proc/sys/net/ipv4/ip_forward

# /etc/sysctl.conf --> net.ipv4.ip_forward = 1
# cat /proc/net/ip_conntrack

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT

if ! [[ -e /usr/local/bin/terraform ]]; then
   mkdir -p /etc/terraform
   DEBIAN_FRONTEND=noninteractive apt-get install -qq -y unzip
   curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip \
    -o /usr/local/bin/terraform.zip
  cd /usr/local/bin &&  unzip terraform.zip
   curl -sLO \
    https://github.com/coreos/terraform-provider-matchbox/releases/download/v${TERRAFORM_MB}/terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64.tar.gz
   tar -xzf terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64.tar.gz
   mv terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64/terraform-provider-matchbox .
   cat<<EOF >/root/.terraformrc
providers {
  matchbox = "/usr/local/bin/terraform-provider-matchbox"
}
EOF
fi
