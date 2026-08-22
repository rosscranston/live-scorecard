.PHONY: validate test package doctor sync dry-sync

validate:
	python3 scripts/validate_repo.py

test:
	python3 -m unittest discover -s tests -p 'test_*.py'

package:
	python3 scripts/package_skills.py

doctor:
	./scripts/doctor.sh

sync:
	./scripts/ai-os-sync.sh

dry-sync:
	./scripts/ai-os-sync.sh --dry-run
