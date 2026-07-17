const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const amountToPesewas = (value: unknown) => {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("Enter a valid payment amount.");
  }
  return Math.round(amount * 100);
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ ok: false, message: "Method not allowed." }, 405);

  try {
    const secret = Deno.env.get("PAYSTACK_SECRET_KEY");
    if (!secret) throw new Error("PAYSTACK_SECRET_KEY is not configured.");

    const input = await request.json();
    const headers = {
      Authorization: `Bearer ${secret}`,
      "Content-Type": "application/json",
    };

    if (input.action === "initialize") {
      const phone = String(input.phone ?? "").replaceAll(/\D/g, "");
      if (phone.length < 9 || phone.length > 15) {
        return json({ ok: false, message: "Enter a valid customer mobile number." }, 400);
      }
      const amount = amountToPesewas(input.amount);
      const reference = `mm_${crypto.randomUUID().replaceAll("-", "")}`;
      const email = `paystack+${reference}@sokkolink.app`;
      const paystackResponse = await fetch("https://api.paystack.co/transaction/initialize", {
        method: "POST",
        headers,
        body: JSON.stringify({
          email,
          amount,
          currency: "GHS",
          reference,
          channels: ["mobile_money", "card"],
          metadata: {
            debt_id: input.debtId,
            sale_id: input.saleId,
            expected_amount: amount,
            source: "market_mate",
            customer_phone: phone,
          },
        }),
      });
      const result = await paystackResponse.json();
      if (!paystackResponse.ok || result.status !== true) {
        return json({ ok: false, message: result.message ?? "Could not start payment." }, 400);
      }
      return json({
        ok: true,
        authorizationUrl: result.data.authorization_url,
        reference: result.data.reference,
      });
    }

    if (input.action === "verify") {
      const reference = String(input.reference ?? "");
      if (!/^mm_[a-f0-9]{32}$/.test(reference)) {
        return json({ paid: false, message: "Invalid payment reference." }, 400);
      }
      const paystackResponse = await fetch(
        `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
        { headers },
      );
      const result = await paystackResponse.json();
      if (!paystackResponse.ok || result.status !== true) {
        return json({ paid: false, message: result.message ?? "Could not verify payment." }, 400);
      }
      const expected = amountToPesewas(input.expectedAmount);
      const metadataAmount = Number(result.data.metadata?.expected_amount);
      const paid = result.data.status === "success" &&
        result.data.currency === "GHS" &&
        result.data.amount === expected &&
        result.data.amount === metadataAmount &&
        result.data.metadata?.source === "market_mate";
      return json({
        paid,
        amount: paid ? result.data.amount / 100 : 0,
        reference: result.data.reference,
        channel: result.data.channel,
        message: paid ? "Payment verified." : "Payment is not successful yet.",
      });
    }

    return json({ ok: false, message: "Unknown action." }, 400);
  } catch (error) {
    return json(
      { ok: false, paid: false, message: error instanceof Error ? error.message : "Unexpected error." },
      500,
    );
  }
});
