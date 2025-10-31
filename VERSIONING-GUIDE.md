# Versioned Update Workflow

This explains the new update system for your Docker learning documentation.

## 📦 Two Download Options

### Option 1: Updates Only (Recommended for Ongoing Work)
**When to use:** You already have the repo set up and just want updates

[Download: updates folder](computer:///mnt/user-data/outputs/updates)

**Contains:**
- V2_ prefixed files (updated versions)
- New files (no prefix)
- README with instructions

### Option 2: Complete Repository
**When to use:** First time setup or you want a fresh copy

[Download: complete docker-learning folder](computer:///mnt/user-data/outputs/docker-learning)

**Contains:**
- Everything including latest versions
- All scripts
- Complete documentation structure

---

## 🔄 The Versioning System

### How It Works

**New Files** → No version prefix
- `common-flags-and-options.md`
- `practical-examples.md`
- Safe to copy - nothing to overwrite

**Updated Files** → Version prefix (V2_, V3_, V4_...)
- `V2_container-lifecycle-commands.md`
- `V2_quick-reference.md`
- Compare with your current version first

### Your Workflow

```bash
# 1. Download the updates folder
# 2. Copy files to your repo
cp -r updates/* docker-learning/

# 3. Move new files to correct location
mv docker-learning/common-flags-and-options.md docker-learning/01-docker-basics/
mv docker-learning/practical-examples.md docker-learning/01-docker-basics/

# 4. Compare updated files
cd docker-learning
./scripts/manage-versions.sh compare 01-docker-basics/V2_container-lifecycle-commands.md

# 5. Accept or reject each update
./scripts/manage-versions.sh accept 01-docker-basics/V2_container-lifecycle-commands.md
./scripts/manage-versions.sh accept V2_quick-reference.md

# 6. Clean up when done
./scripts/manage-versions.sh clean
```

---

## 🛠️ Version Management Commands

```bash
# See all versioned files
./scripts/manage-versions.sh list

# Compare a file (shows diff)
./scripts/manage-versions.sh compare path/to/V2_file.md

# Accept changes (replaces current file)
./scripts/manage-versions.sh accept path/to/V2_file.md

# Reject changes (deletes versioned file)
./scripts/manage-versions.sh reject path/to/V2_file.md

# Remove all V*_ files
./scripts/manage-versions.sh clean
```

---

## ✅ Benefits of This System

1. **Safe** - Never overwrites your notes accidentally
2. **Transparent** - You see exactly what changed
3. **Flexible** - Accept some updates, reject others
4. **Git-friendly** - Easy to commit updates selectively
5. **Clean** - One command removes all versioned files

---

## 📋 Version History

- **V1** - Initial documentation structure (October 30, 2025)
- **V2** - Added docker run, docker search, flags guide, practical examples (October 31, 2025)
- **V3** - (Future updates...)

---

## 💡 Pro Tips

1. **Always commit first**
   ```bash
   git commit -am "My notes before update"
   ```

2. **Review diffs carefully**
   - Green lines = additions
   - Red lines = deletions
   - Your notes might be in the red!

3. **Manual merge when needed**
   - Copy your notes from the old file
   - Add them to the new file
   - Then accept the update

4. **Keep it clean**
   - Run `manage-versions.sh clean` after accepting/rejecting all updates
   - Don't let V*_ files accumulate

---

## 🆘 Troubleshooting

**Q: "I accepted a file but lost my notes!"**
A: Use git to recover: `git checkout HEAD~1 -- path/to/file.md`

**Q: "How do I manually merge changes?"**
A: 
```bash
# 1. Open both files in an editor
code container-lifecycle-commands.md V2_container-lifecycle-commands.md

# 2. Copy your notes to the V2 file
# 3. Accept the merged V2 file
./scripts/manage-versions.sh accept V2_container-lifecycle-commands.md
```

**Q: "Can I just use the new files without comparing?"**
A: Yes! If you trust the updates, just:
```bash
mv V2_file.md file.md
```

---

**Remember:** This system is designed to protect your work while making updates easy!
