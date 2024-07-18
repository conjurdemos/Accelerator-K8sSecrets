#!/bin/bash
helm delete csi-secrets-store -n kube-system
helm delete conjur-csi-provider -n kube-system
