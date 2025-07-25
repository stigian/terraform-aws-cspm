# terraform-aws-cspm Documentation

This directory contains comprehensive documentation for the terraform-aws-cspm module, including architectural decisions, implementation guides, and historical records.

## 📖 User Guides

### [Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)
**Essential reading for customization**  
Complete guide on how to add new Organizational Units and lifecycle phases to your deployment. Covers:
- Adding new OUs without code changes
- Extending lifecycle validation rules
- Complete examples with staging environments
- Best practices and troubleshooting

## 🏗️ Architecture & Strategy

### [Integration Strategy](./integration-strategy.md)
High-level integration patterns and architectural decisions for multi-account AWS deployments.

### [Multi-Account Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md)
Detailed patterns for managing Terraform providers across multiple AWS accounts and regions.

##  Quick References

### Key Configuration Files
- `config/sra-account-types.yaml` - Account type definitions
- `config/account-schema.yaml` - Account parameter schema
- `examples/terraform.tfvars` - Live deployment configuration

### Common Tasks
- **Adding new OUs**: See [Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)
- **Account management**: Check the main [README.md](../README.md)
- **SSO configuration**: See `modules/sso/README.md`
- **Control Tower setup**: See `modules/controltower/README.md`

## 📝 Contributing to Documentation

When adding new documentation:
1. **Create descriptive filenames** using kebab-case
2. **Add entries to this index** with brief descriptions
3. **Include examples** for technical guides
4. **Update cross-references** in related documents
5. **Document architectural decisions** for future reference

## 🔍 Finding Information

### For Implementation Questions
- Start with [Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)
- Check module-specific READMEs in `modules/*/README.md`
- Review example configurations in `examples/`

### For Architectural Context
- Review [Integration Strategy](./integration-strategy.md)
- Check [Multi-Account Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md)

### For Troubleshooting
- Check validation rules in `modules/organizations/variables.tf`
- Review account schema in `config/account-schema.yaml`
- Use `tofu validate` and `tofu plan` commands

---

*Last updated: July 2025*  
*For questions or additions to this documentation, please create an issue or pull request.*
