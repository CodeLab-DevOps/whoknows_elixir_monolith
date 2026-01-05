defmodule WhoknowsElixirMonolithWeb.PageControllerTest do
  use WhoknowsElixirMonolithWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "¿Who Knows?"
  end

  test "renders page successfully", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "¿Who Knows?"
    assert response =~ "<!DOCTYPE html>"
  end

  test "includes theme toggle", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "theme-toggle"
  end
end
