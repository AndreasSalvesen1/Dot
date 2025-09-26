return {
	"lervag/vimtex",
	lazy = false,

	init = function()
		-- --- Viewer: Zathura with proper nvr inverse search ---
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_automatic = 0
		vim.g.vimtex_view_forward_search_on_start = 0
		vim.g.vimtex_view_zathura_use_synctex = 1
		vim.g.vimtex_compiler_silent = 1
		vim.g.vimtex_view_zathura_options = ([[--synctex-editor-command "nvr --servername %s --remote-silent +%%{line} %%{input}"]]):format(
			vim.v.servername
		)
		vim.g.vimtex_view_use_temp_files = 0

		-- Ensure Neovim exposes an RPC server early (so nvr can find it)
		if (vim.v.servername or "") == "" then
			local base = (vim.env.XDG_RUNTIME_DIR or "/tmp")
			local sock = string.format("%s/nvim-%d", base, vim.fn.getpid())
			vim.fn.serverstart(sock)
			vim.env.NVIM_LISTEN_ADDRESS = sock
		end

		-- --- Compiler: latexmk; PDF + synctex in ROOT, aux in build/ ---
		local auxdir = "build"
		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_compiler_latexmk = {
			callback = 1,
			continuous = 0,
			executable = "latexmk",
			options = {
				"-pdf",
				"-interaction=nonstopmode",
				"-synctex=1",
				"-file-line-error",
				"-auxdir=" .. auxdir, -- ✅ aux/logs to build/, but PDF + .synctex.gz stay in root
			},
		}

		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				-- Concealed LaTeX snippets
				vim.api.nvim_set_hl(0, "Conceal", { fg = "#ff9e64", bold = true })

				-- Numbers (5, 25, -4, etc.)
				vim.api.nvim_set_hl(0, "Number", { fg = "#ffd75f", bold = true }) -- bright yellow

				-- Math operators (+, -, =, etc.)
				vim.api.nvim_set_hl(0, "texMathOperator", { fg = "#ffb86c", bold = true }) -- orange

				-- Math symbols (\int, \alpha, ⇒, etc.)
				vim.api.nvim_set_hl(0, "texMathSymbol", { fg = "#ffcc66" }) -- golden yellow

				-- Math delimiters ($ ... $)
				vim.api.nvim_set_hl(0, "texMathDelimZone", { fg = "#ffaa44" }) -- orange tint

				-- Optional: tint whole math environments slightly
				vim.api.nvim_set_hl(0, "texMathZoneX", { fg = "#ffde96" }) -- softer yellow background tone
			end,
		})

		-- --- Quickfix + conceal prefs ---
		vim.g.vimtex_quickfix_mode = 0
		vim.g.tex_conceal = "abdmg"
		vim.g.vimtex_syntax_conceal = {
			accents = 3,
			cites = 3,
			fancy = 3,
			greek = 3,
			math_bounds = 3,
			math_delimiters = 3,
			math_fracs = 3,
			math_super_sub = 3,
			math_symbols = 3,
			sections = 3,
			styles = 3,
			items = 1,
			environments = 1,
		}

		--------------------------------------------------------------------------
		-- Helper: forward-sync without leaving the current Hyprland window
		--------------------------------------------------------------------------

		-- NEW: forward-sync that won't spawn a new Zathura if VimTeX doesn't own it
		local function do_forward_sync_without_spawning()
			-- If VimTeX already manages a viewer, let it handle reuse
			local has_view = false
			pcall(function()
				has_view = (vim.fn["vimtex#view#is_open"]() == 1)
			end)
			if has_view then
				pcall(vim.cmd, "silent! VimtexView")
				return
			end

			-- Otherwise, forward-sync to the existing Zathura YOU started
			local line = vim.fn.line(".")
			local col = math.max(1, vim.fn.col(".") - 1)
			local src = vim.fn.expand("%:p")
			local pdf = vim.fn.expand("%:p:r") .. ".pdf"
			if vim.fn.filereadable(pdf) == 1 then
				vim.fn.jobstart({
					"zathura",
					"--synctex-forward",
					string.format("%d:%d:%s", line, col, src),
					pdf,
				}, { detach = true })
			end
		end

		local function VimtexView_no_focus(delay_ms)
			local prev_addr = nil
			if vim.fn.executable("hyprctl") == 1 then
				local out = vim.fn.system({ "hyprctl", "-j", "activewindow" })
				if out ~= "" then
					local ok, data = pcall(vim.json.decode, out)
					if ok and type(data) == "table" then
						prev_addr = data.address
					end
				end
			end

			-- MINIMAL CHANGE: avoid spawning a second Zathura
			do_forward_sync_without_spawning()

			if prev_addr then
				vim.defer_fn(function()
					vim.fn.system({ "hyprctl", "dispatch", "focuswindow", "address:" .. prev_addr })
				end, delay_ms or 60) -- 40–80ms feels smooth; 60ms default
			end
		end
		--------------------------------------------------------------------------

		-- UI + keymaps + autosync in TeX buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "tex", "plaintex", "latex" },
			callback = function(ev)
				vim.opt_local.conceallevel = 2
				vim.opt_local.concealcursor = "nc"

				-- ✅ use the helper here (keeps focus on Neovim)
				vim.keymap.set("n", "|", function()
					VimtexView_no_focus(80)
				end, { buffer = ev.buf, desc = "VimTeX: forward sync (no focus)" })

				-- ✅ and here too (insert-mode hotkey)
				vim.keymap.set("i", "<C-|>", function()
					VimtexView_no_focus(80)
				end, { buffer = ev.buf, desc = "VimTeX: forward sync (no focus)" }) -- Mark-and-write mapping
				vim.keymap.set({ "n", "i" }, "<C-s>", function()
					vim.b._vimtex_compile_on_this_write = true
					vim.cmd("silent! write!") -- force an actual BufWritePost
				end, { buffer = ev.buf, desc = "Save + compile (vimtex, instant)" })

				-- Single BufWritePost that only fires if we set the flag
				local grp = vim.api.nvim_create_augroup("tex_compile_on_ctrls_" .. ev.buf, { clear = true })
				vim.api.nvim_create_autocmd("BufWritePost", {
					buffer = ev.buf,
					group = grp,
					callback = function()
						if vim.b._vimtex_compile_on_this_write then
							vim.b._vimtex_compile_on_this_write = nil
							-- Prefer instant single-shot; avoids pvc/polling
							if pcall(vim.cmd, "silent! VimtexCompileSS") then
								return
							end
							-- Fallback if SS unavailable
							pcall(vim.cmd, "silent! VimtexCompile")
						end
					end,
					desc = "Compile after <C-s> write only",
				})
			end,
		})

		-- Sanity checks on startup
		vim.api.nvim_create_autocmd("VimEnter", {
			once = true,
			callback = function()
				if vim.fn.executable("latexmk") == 0 then
					vim.notify("[vimtex] latexmk not found in PATH", vim.log.levels.WARN)
				end
				if vim.fn.executable("zathura") == 0 then
					vim.notify("[vimtex] zathura not found in PATH", vim.log.levels.WARN)
				end
			end,
		})
	end,

	config = function()
		-- --- Helpers (no root/build PDF confusion anymore) ---
		local function paths_for_buf(bufnr)
			local name = vim.api.nvim_buf_get_name(bufnr)
			local dir = vim.fn.fnamemodify(name, ":p:h")
			local stem = vim.fn.fnamemodify(name, ":t:r")
			local root_pdf = ("%s/%s.pdf"):format(dir, stem)
			local tex_file = ("%s/%s.tex"):format(dir, stem)
			return root_pdf, tex_file, dir
		end

		-- Instant compile on save, always
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "tex", "plaintex", "latex" },
			callback = function(ev)
				-- <C-s> = write then compile
				vim.keymap.set({ "n", "i" }, "<C-s>", function()
					vim.cmd("silent! write")
					-- single-shot: starts immediately, no polling
					pcall(vim.cmd, "silent! VimtexCompileSS")
				end, { buffer = ev.buf, desc = "Save + compile (instant)" })

				-- Also compile on any write (e.g., autosave, :w)
				vim.api.nvim_create_autocmd("BufWritePost", {
					buffer = ev.buf,
					callback = function()
						pcall(vim.cmd, "silent! VimtexCompileSS")
					end,
					desc = "Instant compile on save",
				})
			end,
		})

		-- After successful compile, (re)open viewer on the root PDF once
		vim.api.nvim_create_autocmd("User", {
			pattern = "VimtexEventCompileSuccess",
			callback = function(args)
				local bufnr = args.buf or 0
				local name = vim.api.nvim_buf_get_name(bufnr)
				local dir = vim.fn.fnamemodify(name, ":p:h")
				local pdf = dir .. "/" .. vim.fn.fnamemodify(name, ":t:r") .. ".pdf"
				if vim.fn.executable("zathura") == 1 and vim.fn.filereadable(pdf) == 1 then
					-- start once per buffer
					if not vim.b[bufnr].zathura_job or vim.fn.jobwait({ vim.b[bufnr].zathura_job }, 0)[1] ~= -1 then
						vim.b[bufnr].zathura_job = vim.fn.jobstart({ "zathura", pdf }, { detach = false, cwd = dir })
					end
				end
			end,
		})

		local function needs_compile(bufnr)
			local root_pdf, tex_file = paths_for_buf(bufnr)
			local tex_m = vim.fn.getftime(tex_file)
			local pdf_m = vim.fn.getftime(root_pdf)
			if tex_m == -1 then
				return false
			end
			if pdf_m == -1 then
				return true
			end
			return pdf_m < tex_m
		end

		local function is_job_running(jobid)
			if not jobid then
				return false
			end
			local ok, res = pcall(vim.fn.jobwait, { jobid }, 0)
			return ok and type(res) == "table" and res[1] == -1
		end

		local function start_zathura_once(bufnr, pdf, cwd)
			if not pdf or vim.fn.executable("zathura") ~= 1 then
				return
			end
			if is_job_running(vim.b[bufnr].zathura_job) then
				return
			end
			if vim.fn.filereadable(pdf) ~= 1 then
				return
			end

			-- remember current Hyprland focused window (so we can return to nvim)
			local prev_addr = nil
			if vim.fn.executable("hyprctl") == 1 then
				local out = vim.fn.system({ "hyprctl", "-j", "activewindow" })
				if out ~= "" then
					local ok, data = pcall(vim.json.decode, out)
					if ok and type(data) == "table" then
						prev_addr = data.address
					end
				end
			end

			-- start zathura
			local job = vim.fn.jobstart({ "zathura", pdf }, { detach = false, cwd = cwd })
			if type(job) == "number" and job > 0 then
				vim.b[bufnr].zathura_job = job
				-- refocus back to the previously active window (usually your terminal/nvim)
				if prev_addr then
					vim.defer_fn(function()
						vim.fn.system({ "hyprctl", "dispatch", "focuswindow", "address:" .. prev_addr })
					end, 150) -- tune: 120–220ms if needed
				end
			end
		end

		local function stop_zathura(bufnr)
			local job = vim.b[bufnr].zathura_job
			if is_job_running(job) then
				pcall(vim.fn.jobstop, job)
			end
			vim.b[bufnr].zathura_job = nil
		end

		-- --- On open: compile if needed, open existing PDF once ---
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
			pattern = "*.tex",
			callback = function(args)
				local bufnr = args.buf
				if needs_compile(bufnr) then
					vim.schedule(function()
						pcall(vim.cmd, "silent! VimtexCompile")
					end)
				end
				if not vim.b[bufnr]._autoview_opened then
					vim.schedule(function()
						local root_pdf, _, dir = paths_for_buf(bufnr)
						if vim.fn.filereadable(root_pdf) == 1 then
							start_zathura_once(bufnr, root_pdf, dir)
							vim.b[bufnr]._autoview_opened = true
						end
					end)
				end
			end,
			desc = "Initial compile if needed + open existing PDF once",
		})

		-- --- After successful compile: ensure viewer is running on ROOT pdf ---
		vim.api.nvim_create_autocmd("User", {
			pattern = "VimtexEventCompileSuccess",
			callback = function(args)
				local bufnr = args.buf or 0
				local root_pdf, _, dir = paths_for_buf(bufnr)
				start_zathura_once(bufnr, root_pdf, dir)
			end,
			desc = "Post-compile: (re)open viewer on root PDF",
		})

		-- --- Close Zathura when the TeX buffer is closed ---
		vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
			pattern = "*.tex",
			callback = function(args)
				stop_zathura(args.buf)
			end,
			desc = "Close Zathura when TeX buffer closes",
		})

		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()
				stop_zathura(bufnr)
			end,
		})
	end,
}
