defmodule Electro.Pdf do

  @dpi_cm 72.0 / 2.54

  def gen_label(part, path) do
    h = 6.2 * @dpi_cm
    Pdf.build([size: [10 * @dpi_cm, h], compress: true], fn pdf ->
      {pdf, _} =
        pdf
        |> Pdf.set_info(title: "Label")
        |> Pdf.set_font("Helvetica", 20)
        |> Pdf.text_at({20, h - 35}, to_string(part.id))
        |> Pdf.text_at({160, h - 35}, part[:location] |> txt())
        |> Pdf.set_font("Helvetica", 12)
        |> Pdf.text_at({20, h - 60}, part[:name] |> txt())
        |> Pdf.text_at({20, h - 80}, part[:mpn] |> txt())
        |> Pdf.text_wrap({20, h - 90}, {200, 60}, part[:description] |> txt())
      Pdf.write_to(pdf, path)
    end)
  end

  def print_label(part) do
    {:ok, tmp_path} = Temp.path(%{suffix: ".pdf"})
    gen_label(part, tmp_path)
    # TODO allow configuration of that command
    System.cmd("lp", ["-d",  "brother_ql", "-o", "PageSize=62x100", tmp_path])
    File.rm(tmp_path)
  end

  defp txt(nil), do: ""

  defp txt(str) do
  str
  |> String.to_charlist()
  |> Enum.filter(&(&1 in 0..127))
  |> List.to_string
  end
end
