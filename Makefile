.PHONY: server

server: deps
	iex -S mix phx.server


.PHONY: deps

deps:
	mix deps.get
