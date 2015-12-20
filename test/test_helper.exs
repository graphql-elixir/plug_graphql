ExUnit.start(exclude: [])

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions
  use Plug.Test

  def assert_query(plug, {method, path, params}, {status, body}) do
    assert_response plug, conn(method, path, params), status, body
  end

  def assert_response(plug, conn, status, body) do
    conn = plug.call conn, []

    assert conn.status == status
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == body
  end
end
